
alias opt_ball_count       = script_option[0]
alias opt_auto_pickup      = script_option[1]
alias opt_hot_potato       = script_option[2]
alias opt_bomb_fuse_time   = script_option[3]
alias opt_bomb_random_time = script_option[4]

alias carrier_traits = script_traits[0]

-- Unnamed Forge labels:
alias all_skulls = 2
alias all_bombs  = 3

alias carry_time = player.script_stat[0]
alias ball_kills = player.script_stat[1]

alias announced_game_start = player.number[0]
alias announce_start_timer = player.timer[2]

alias extant_ball_count = global.number[0]
alias temp_int_00       = global.number[1] -- unused
alias temp_int_01       = global.number[2] -- unused
alias temp_int_02       = global.number[3]
alias temp_int_03       = global.number[4]
alias temp_plr_00       = global.player[0]
alias temp_plr_01       = global.player[1]
alias announce_initial_ball_spawn_timer = global.timer[0]
alias is_carried        = object.number[0]
alias has_nearby_ball   = object.number[1] -- don't spawn a new ball at a spawn point if another ball is nearby
alias current_carrier   = object.player[0]
alias last_announced_carrier = object.player[1]
alias reset_timer       = object.timer[0] -- runs while the ball is dropped
alias fuse_timer        = object.timer[1]
alias announce_cooldown = object.timer[2] -- avoid announcing taken/dropped events too quickly
alias announced_30s_win = player.number[1]
alias announced_60s_win = player.number[2]
alias is_carrier        = player.number[3]
alias carry_time_update = player.timer[0] -- update interval for Carry Time stat
alias announced_30s_win = team.number[0]
alias announced_60s_win = team.number[1]

declare extant_ball_count with network priority local
declare temp_int_00       with network priority local
declare temp_int_01       with network priority local
declare temp_int_02       with network priority local
declare temp_int_03       with network priority local
declare global.object[0] with network priority local
declare global.object[1] with network priority local
declare global.object[2] with network priority local
declare temp_plr_00       with network priority local
declare temp_plr_01       with network priority local
declare announce_initial_ball_spawn_timer = 6
declare player.announced_game_start with network priority low
declare player.announced_30s_win    with network priority low
declare player.announced_60s_win    with network priority low
declare player.is_carrier with network priority low
declare player.carry_time_update = 1
declare player.timer[1] = 3 -- purpose unknown. nothing ever checks if it's zero
declare player.announce_start_timer = 5
declare object.is_carried      with network priority low
declare object.has_nearby_ball with network priority local
declare object.current_carrier with network priority low
declare object.last_announced_carrier with network priority low
declare object.reset_timer       = 15
declare object.fuse_timer        = opt_bomb_fuse_time
declare object.announce_cooldown = 3
declare team.announced_30s_win with network priority low
declare team.announced_60s_win with network priority low

if game.teams_enabled == 1 then -- enforce FFA-only label
   for each object with label "ffa_only" do
      current_object.delete()
   end
end

if game.teams_enabled == 0 then -- enforce team-only label
   for each object with label "team_only" do
      current_object.delete()
   end
end

on init: do -- handle initial ball spawns
   announce_initial_ball_spawn_timer.set_rate(-100%)
   --
   alias min_spawn_sequence = temp_int_02
   --
   min_spawn_sequence = 10000
   for each object with label "oddball_ball" do
      if current_object.has_nearby_ball == 0 and current_object.spawn_sequence < min_spawn_sequence then 
         min_spawn_sequence = current_object.spawn_sequence
      end
   end
   for each object with label "oddball_ball" do
      if extant_ball_count < opt_ball_count and current_object.spawn_sequence == min_spawn_sequence and current_object.has_nearby_ball == 0 then 
         alias new_ball       = global.object[0]
         alias new_anti_spawn = global.object[1]
         --
         new_ball = no_object
         if opt_hot_potato == 0 then 
            new_ball = current_object.place_at_me(skull, none, never_garbage_collect, 0, 0, 5, none)
            if current_object.is_of_type(capture_plate) or current_object.is_of_type(flag_stand) then 
               new_ball.attach_to(current_object, 0, 0, 2, absolute)
            end
         end
         if opt_hot_potato == 1 then 
            new_ball = current_object.place_at_me(bomb, none, never_garbage_collect, 0, 0, 5, none)
            if current_object.is_of_type(capture_plate) or current_object.is_of_type(flag_stand) then 
               new_ball.attach_to(current_object, 0, 0, 2, absolute)
            end
            temp_int_03 = 0
            temp_int_03 = rand(opt_bomb_random_time)
            new_ball.fuse_timer += temp_int_03
         end
         --
         -- Perform setup tasks for the new ball:
         --
         --  - Attach a weak-anti spawn zone to it, so that spawning near the ball 
         --    is discouraged.
         --
         --  - Set the ball's waypoint and shape.
         --
         --  - Set whether auto-pickup is enabled.
         --
         new_anti_spawn = no_object
         new_anti_spawn = current_object.place_at_me(respawn_zone_weak_anti, none, never_garbage_collect, 0, 0, 0, none)
         new_anti_spawn.team = neutral_team
         new_anti_spawn.attach_to(new_ball, 0, 0, 0, absolute)
         --
         new_ball.set_waypoint_icon(skull)
         new_ball.set_waypoint_priority(high)
         new_ball.set_shape(sphere, 10)
         current_object.has_nearby_ball = 1
         new_ball.is_carried = 0
         extant_ball_count += 1
         new_ball.set_weapon_pickup_priority(hold_action)
         if opt_auto_pickup == 1 then 
            new_ball.set_weapon_pickup_priority(automatic)
         end
      end
   end
   for each player do
      current_player.timer[1].reset()
      current_player.timer[1].set_rate(-100%)
   end
end

for each player do -- loadout palettes
   if current_player.is_elite() then 
      current_player.set_loadout_palette(elite_tier_1)
   end
   if not current_player.is_elite() then 
      current_player.set_loadout_palette(spartan_tier_1)
   end
end

for each player do -- why is this its own trigger? lol
   current_player.announce_start_timer.set_rate(-100%)
end
for each player do -- round card and announce game start
   if current_player.announced_game_start == 0 then 
      if game.score_to_win != 0 and opt_hot_potato == 0 then 
         current_player.set_round_card_title("Hold the skull to earn points.\r\n%n points to win.", game.score_to_win)
      end
      if game.score_to_win != 0 and opt_hot_potato == 1 then 
         current_player.set_round_card_title("Hold the ticking bomb to earn points.\r\n%n points to win.", game.score_to_win)
      end
      if game.score_to_win == 0 and opt_hot_potato == 0 then 
         current_player.set_round_card_title("Hold the skull to earn points.")
      end
      if game.score_to_win == 0 and opt_hot_potato == 1 then 
         current_player.set_round_card_title("Hold the ticking bomb to earn points.")
      end
      if current_player.announce_start_timer.is_zero() then 
         send_incident(ball_game_start, current_player, no_player)
         current_player.announced_game_start = 1
      end
   end
end

if announce_initial_ball_spawn_timer.is_zero() then 
   send_incident(ball_spawned, all_players, all_players)
   announce_initial_ball_spawn_timer.reset()
   --
   -- Hm... Does a timer's rate switch to 0% if it was previously negative and 
   -- the timer hits zero?
   --
end

on host migration: do
   for each player do
      current_player.carry_time_update.set_rate(0%)
      current_player.carry_time_update.reset()
   end
end

do -- maintain an accurate count of the number of balls in play
   extant_ball_count = 0
   for each object with label all_skulls do
      extant_ball_count += 1
   end
   for each object with label all_bombs do
      extant_ball_count += 1
   end
end

for each player do -- reset player carry-related state, to be restored later
   --
   -- Reset some player carry-related state; we'll restore it in triggers further 
   -- below if we need to.
   --
   current_player.carry_time_update.set_rate(0%)
   current_player.biped.set_waypoint_icon(none)
   current_player.biped.set_waypoint_priority(normal)
   if not current_player.killer_type_is(guardians | suicide | kill | betrayal | quit) then 
      --
      -- Reset the "is_carrier" property for living players only. We will re-check 
      -- it in a later trigger. For dead players, we want to avoid resetting the 
      -- property so that we can check (in triggers further below) whether a killed 
      -- player was a carrier.
      --
      current_player.is_carrier = 0
   end
end

for each object with label "oddball_ball" do -- prepare to track whether ball spawns have balls nearby
   current_object.has_nearby_ball = 0
   current_object.set_shape(cylinder, 20, 10, 10)
end
for each object with label all_skulls do -- handle ball resets, waypoints, etc.
   alias current_ball    = global.object[0]
   alias current_carrier = temp_plr_00
   --
   current_ball = current_object
   if current_ball.reset_timer.is_zero() then 
      current_ball.delete()
   end
   if current_ball.is_out_of_bounds() then 
      current_ball.delete()
   end
   if not current_ball == no_object then -- if we didn't delete the object
      current_ball.reset_timer.set_rate(-100%)
      for each object with label "oddball_ball" do
         if current_object.shape_contains(current_ball) then 
            current_object.has_nearby_ball = 1
            current_ball.reset_timer.reset() -- don't reset balls that are near spawn points
         end
      end
      current_ball.team = neutral_team
      current_ball.set_waypoint_visibility(everyone)
      current_ball.set_waypoint_priority(high)
      current_ball.set_waypoint_icon(skull)
      current_carrier = no_player
      current_carrier = current_ball.try_get_carrier()
      if not current_carrier == no_player then 
         current_ball.team = current_carrier.team
         current_ball.current_carrier = current_carrier
         current_carrier.apply_traits(carrier_traits)
         current_carrier.carry_time_update.set_rate(-100%)
         current_carrier.is_carrier = 1
         current_carrier.biped.set_waypoint_icon(skull)
         current_carrier.biped.set_waypoint_priority(high)
         current_ball.set_waypoint_visibility(no_one)
         current_ball.reset_timer.reset()
         current_carrier.timer[1].set_rate(-100%)
      end
   end
end
for each object with label all_bombs do -- handle bomb resets, waypoints, etc., along with the fuse timer
   alias current_ball    = global.object[0]
   alias current_carrier = temp_plr_00
   --
   if opt_hot_potato == 1 then 
      current_ball = current_object
      current_ball.set_waypoint_icon(bomb)
      if current_ball.reset_timer.is_zero() then 
         current_ball.delete()
      end
      if current_ball.is_out_of_bounds() then 
         current_ball.delete()
      end
      if not current_ball == no_object then -- if we didn't delete the object
         current_ball.reset_timer.set_rate(-100%)
         current_ball.fuse_timer.set_rate(0%)
         for each object with label "oddball_ball" do
            if current_object.shape_contains(current_ball) then 
               current_object.has_nearby_ball = 1
               current_ball.reset_timer.reset() -- don't reset balls that are near spawn points
            end
         end
         current_ball.set_waypoint_visibility(everyone)
         current_carrier = no_player
         current_carrier = current_ball.try_get_carrier()
         if not current_carrier == no_player then 
            current_carrier.apply_traits(carrier_traits)
            current_carrier.carry_time_update.set_rate(-100%)
            current_carrier.is_carrier = 1
            current_carrier.biped.set_waypoint_icon(bomb)
            current_ball.set_waypoint_visibility(no_one)
            current_ball.reset_timer.reset()
            current_ball.fuse_timer.set_rate(-100%)
            if current_ball.fuse_timer.is_zero() then 
               current_ball.kill(false)
               current_ball.biped.kill(false)
            end
         end
      end
   end
end

for each object with label all_skulls do -- blink waypoints on oddballs about to reset
   alias current_ball = global.object[0]
   if current_object.is_of_type(skull) then -- oh. okay.
      current_ball = current_object
      if current_ball.reset_timer < 6 then 
         current_ball.set_waypoint_priority(blink)
      end
   end
end

if extant_ball_count < opt_ball_count then -- respawn balls when they're deleted
   alias current_spawn_point = global.object[0]
   alias new_ball            = global.object[1]
   alias new_anti_spawn      = global.object[2]
   --
   current_spawn_point = no_object
   current_spawn_point = get_random_object("oddball_ball", no_object)
   if current_spawn_point.has_nearby_ball == 0 then 
      new_ball = no_object
      if opt_hot_potato == 0 then 
         new_ball = current_spawn_point.place_at_me(skull, none, never_garbage_collect, 0, 0, 5, none)
         if current_spawn_point.is_of_type(capture_plate) or current_spawn_point.is_of_type(flag_stand) then 
            new_ball.attach_to(current_spawn_point, 0, 0, 2, absolute)
         end
      end
      if opt_hot_potato == 1 then 
         new_ball = current_spawn_point.place_at_me(bomb, none, never_garbage_collect, 0, 0, 5, none)
         if current_spawn_point.is_of_type(capture_plate) or current_spawn_point.is_of_type(flag_stand) then 
            new_ball.attach_to(current_spawn_point, 0, 0, 2, absolute)
         end
         temp_int_02 = 0
         temp_int_02 = rand(opt_bomb_random_time)
         new_ball.fuse_timer += temp_int_02
      end
      --
      -- Perform setup tasks for the new ball:
      --
      --  - Attach a weak-anti spawn zone to it, so that spawning near the ball 
      --    is discouraged.
      --
      --  - Set the ball's waypoint and shape.
      --
      --  - Set whether auto-pickup is enabled.
      --
      new_anti_spawn = no_object
      new_anti_spawn = new_ball.place_at_me(respawn_zone_weak_anti, none, never_garbage_collect, 0, 0, 0, none)
      extant_ball_count += 1
      new_anti_spawn.team = neutral_team
      new_anti_spawn.attach_to(new_ball, 0, 0, 0, absolute)
      --
      new_ball.set_waypoint_icon(skull)
      new_ball.set_waypoint_priority(high)
      new_ball.set_shape(sphere, 10)
      current_spawn_point.has_nearby_ball = 1
      extant_ball_count += 1
      send_incident(ball_reset, all_players, all_players)
      new_ball.is_carried = 0
      new_ball.set_weapon_pickup_priority(hold_action)
      if opt_auto_pickup == 1 then 
         new_ball.set_weapon_pickup_priority(automatic)
      end
   end
end

for each player do -- update players' Carry Time stats
   if current_player.carry_time_update.is_zero() then 
      current_player.score += 1
      current_player.carry_time_update.reset()
      current_player.timer[1].reset()
   end
   current_player.carry_time = current_player.score
end

for each object with label all_skulls do -- handle a ball being carried
   if current_object.is_carried == 0 then 
      temp_plr_00 = no_player
      temp_plr_00 = current_object.try_get_carrier()
      if temp_plr_00 != no_player then 
         current_object.is_carried = 1
      end
   end
end

for each object with label all_skulls do -- announce the ball being taken or dropped
   alias current_carrier = temp_plr_00
   --
   current_object.announce_cooldown.set_rate(-100%)
   if current_object.announce_cooldown.is_zero() then 
      current_carrier = no_player
      current_carrier = current_object.try_get_carrier()
      if current_carrier == no_player and current_object.last_announced_carrier != no_player then 
         if game.teams_enabled == 0 then 
            send_incident(ball_dropped, current_object.last_announced_carrier, current_object.last_announced_carrier)
         end
         if game.teams_enabled == 1 then 
            temp_plr_01 = current_object.last_announced_carrier
            send_incident(ball_dropped_team, temp_plr_01.team, temp_plr_01.team)
         end
         current_object.last_announced_carrier = no_player
         current_object.announce_cooldown.reset()
      end
      if current_carrier != no_player and current_carrier != current_object.last_announced_carrier then 
         send_incident(ball_taken, current_carrier, all_players)
         current_object.last_announced_carrier = current_carrier
         current_object.announce_cooldown.reset()
      end
   end
end

for each object with label all_skulls do -- handle a ball being dropped
   global.object[0] = current_object
   if global.object[0].current_carrier != no_player then 
      temp_plr_00 = no_player
      temp_plr_00 = global.object[0].try_get_carrier()
      if temp_plr_00 == no_player then 
         if game.teams_enabled == 0 then 
         end
         if game.teams_enabled == 1 then 
            temp_plr_01 = global.object[0].current_carrier
         end
         global.object[0].current_carrier = no_player
         current_object.is_carried = 0
      end
   end
end

if opt_auto_pickup == 1 then -- manage auto-pickup for balls even after they've spawned (could be a host migration failsafe?)
   for each object with label all_skulls do
      current_object.set_weapon_pickup_priority(automatic)
   end
   for each object with label all_bombs do
      current_object.set_weapon_pickup_priority(automatic)
   end
end

do -- set ball shapes. (why? we never check them. does this control the auto-pickup radius?)
   for each object with label all_skulls do
      if current_object.is_carried == 0 then 
         current_object.set_shape(sphere, 10)
      end
   end
   for each object with label all_bombs do
      if current_object.is_carried == 0 then 
         current_object.set_shape(sphere, 10)
      end
   end
end

if game.round_time_limit > 0 and game.round_timer.is_zero() then -- round timer
   game.end_round()
end

do -- announce 30s to win and 60s to win
   alias threshold_30s = temp_int_02
   alias threshold_60s = temp_int_03
   for each player do -- FFA
      if game.teams_enabled == 0 then 
         threshold_30s = game.score_to_win
         threshold_60s = game.score_to_win
         threshold_30s -= 30
         threshold_60s -= 60
         if game.score_to_win > 60 and current_player.score >= threshold_60s and current_player.announced_60s_win == 0 then 
            send_incident(one_minute_win, current_player, all_players)
            current_player.announced_60s_win = 1
         end
         if game.score_to_win > 30 and current_player.score >= threshold_30s and current_player.announced_30s_win == 0 then 
            send_incident(half_minute_win, current_player, all_players)
            current_player.announced_30s_win = 1
         end
      end
   end
   for each team do -- Team
      if game.teams_enabled == 1 and current_team.has_any_players() then 
         threshold_30s = game.score_to_win
         threshold_60s = game.score_to_win
         threshold_30s -= 30
         threshold_60s -= 60
         if game.score_to_win > 60 and current_team.score >= threshold_60s and current_team.announced_60s_win == 0 then 
            send_incident(one_minute_team_win, current_team, all_players)
            current_team.announced_60s_win = 1
         end
         if game.score_to_win > 30 and current_team.score >= threshold_30s and current_team.announced_30s_win == 0 then 
            send_incident(half_minute_team_win, current_team, all_players)
            current_team.announced_30s_win = 1
         end
      end
   end
end

for each player do -- award Ball Carrier Kill medal as appropriate
   alias killer = temp_plr_00
   if current_player.killer_type_is(kill) and current_player.is_carrier == 1 then 
      killer = no_player
      killer = current_player.try_get_killer()
      if killer != no_player then 
         send_incident(ball_carrier_kill, killer, current_player)
      end
   end
end

for each player do -- track kills by ball carriers
   alias killer = temp_plr_00
   if current_player.killer_type_is(kill) then 
      killer = no_player
      killer = current_player.try_get_killer()
      if killer.is_carrier == 1 then
         temp_int_02 = 0
         temp_int_02 = current_player.try_get_death_damage_mod()
         if temp_int_02 == enums.damage_reporting_modifier.pummel
         or temp_int_02 == enums.damage_reporting_modifier.assassination
         then 
            --
            -- We want to filter kills by the death damage modifier so that we can 
            -- track only kills that are likely to have occurred with the ball. One 
            -- example of an edge-case that we want to avoid is throwing a grenade, 
            -- picking up the ball, and then having the grenade detonate and kill 
            -- another player.
            --
            killer.ball_kills += 1
         end
      end
   end
end
