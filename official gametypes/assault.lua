
alias opt_sides = script_option[0]
enum sides
   multi
   one_sided
   neutral
   grifball = 7
end
alias opt_arm_time         = script_option[1]
alias opt_fuse_time        = script_option[2]
alias opt_disarm_time      = script_option[3]
alias opt_reset_time       = script_option[4]
alias opt_reset_on_disarm  = script_option[5]
alias opt_carrier_cooldown = script_option[6] -- for some reason, this has only blank strings

-- Unnamed Forge labels:
alias all_bombs   = 6
alias all_hammers = 7
alias all_swords  = 8

alias carrier_traits  = script_traits[0]
alias cooldown_traits = script_traits[1]

alias ui_you_arming = script_widget[0]
alias ui_foe_arming = script_widget[1]
alias ui_disarming  = script_widget[2]

alias bombs_planted = player.script_stat[0]
alias detonations   = player.script_stat[1]
alias carry_time    = player.script_stat[2]
alias defuses       = player.script_stat[3]

alias announced_game_start = player.number[0]
alias announce_start_timer = player.timer[1]

enum bomb_state
   initial = 0
   carried = 1
   dropped = 2
   armed   = 3
end

alias sudden_death_enabled   = global.number[0]
alias announced_sudden_death = global.number[1]
alias temp_int_00  = global.number[2]
alias temp_int_01  = global.number[3]
alias temp_tem_00  = global.team[0]
alias temp_tem_01  = global.team[1]
alias state        = object.number[0]
alias abandoned    = object.number[1] -- for weapons in Grifball
alias planted_on   = object.object[0]
alias owner        = object.team[0]
alias reset_timer  = object.timer[0]
alias arm_timer    = object.timer[1]
alias disarm_timer = object.timer[2]
alias fuse_timer   = object.timer[3]
alias is_disarming = player.number[1]
alias carry_time_update_interval = player.timer[0]
alias carrier_cooldown_timer     = player.timer[2]
alias active_goal       = team.object[0]
alias active_bomb_spawn = team.object[1]
alias current_bomb      = team.object[2]
alias armed_anti_zone   = team.object[3] -- a Respawn Zone, Weak Anti attached to the bomb, which activates when it's armed
alias last_carrier      = team.player[0]
alias last_announced_carrier = team.player[1]
alias announce_juggle_cooldown = team.timer[0] -- don't announce bomb taken/dropped too repeatedly

declare sudden_death_enabled   with network priority local
declare announced_sudden_death with network priority local
declare temp_int_00 with network priority local
declare temp_int_01 with network priority local
declare global.object[0] with network priority local
declare global.object[1] with network priority local
declare global.player[0] with network priority local
declare global.player[1] with network priority local
declare temp_tem_00 with network priority local
declare temp_tem_01 with network priority local
declare player.announced_game_start with network priority low
declare player.is_disarming with network priority low
declare player.carry_time_update_interval = 1 -- increase Bomb Carry Time stat by 1 every 1 second
declare player.announce_start_timer = 5
declare object.state      with network priority low
declare object.abandoned  with network priority local
declare object.planted_on with network priority low
declare object.owner      with network priority low
declare object.reset_timer  = opt_reset_time
declare object.arm_timer    = opt_arm_time
declare object.disarm_timer = opt_disarm_time
declare object.fuse_timer   = opt_fuse_time
declare team.active_goal       with network priority low
declare team.active_bomb_spawn with network priority low
declare team.current_bomb      with network priority low
declare team.armed_anti_zone   with network priority low
declare team.last_carrier with network priority low
declare team.last_announced_carrier with network priority low
declare team.announce_juggle_cooldown = 3

do
   sudden_death_enabled = 0
end

on pregame: do -- set symmetry
   game.symmetry = 1
   if opt_sides == sides.one_sided then 
      game.symmetry = 0
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

for each player do -- set up HUD widgets, round card, and announce game start timer
   ui_you_arming.set_text("Arming Bomb...")
   ui_foe_arming.set_text("Enemy Arming Bomb!")
   ui_you_arming.set_visibility(current_player, false)
   ui_foe_arming.set_visibility(current_player, false)
   ui_disarming.set_text("Disarming Bomb...")
   ui_disarming.set_visibility(current_player, false)
   current_player.announce_start_timer.set_rate(-100%)
   if opt_sides == sides.multi and game.score_to_win != 0 then 
      current_player.set_round_card_title("Detonate the bomb in the enemy's base.\r\n%n points to win.", game.score_to_win)
   end
   if opt_sides == sides.multi and game.score_to_win == 0 then 
      current_player.set_round_card_title("Detonate the bomb in the enemy's base.")
   end
   if opt_sides == sides.one_sided then 
      if current_player.team == team[1] then 
         current_player.set_round_card_title("Detonate your bomb in the enemy's base!\r\n1 point to win round, %n rounds.", game.round_limit)
         current_player.set_round_card_text("Offense")
         current_player.set_round_card_icon(attack)
      end
      if current_player.team == team[0] then 
         current_player.set_round_card_title("Defend your base from the enemy bomb.\r\n1 point to win round, %n rounds.", game.round_limit)
         current_player.set_round_card_text("Defense")
         current_player.set_round_card_icon(defend)
      end
   end
   if opt_sides == sides.neutral and game.score_to_win != 0 then 
      current_player.set_round_card_title("Detonate the bomb in the enemy's base.\r\n%n points to win.", game.score_to_win)
   end
   if opt_sides == sides.neutral and game.score_to_win == 0 then 
      current_player.set_round_card_title("Detonate the bomb in the enemy's base.")
   end
   if opt_sides == sides.grifball and game.score_to_win != 0 then 
      current_player.set_round_card_title("Detonate the bomb in the enemy's goal.\r\n%n points to win.", game.score_to_win)
   end
   if opt_sides == sides.grifball and game.score_to_win == 0 then 
      current_player.set_round_card_title("Detonate the bomb in the enemy's goal.")
   end
end
for each player do -- announce game start (standard)
   if  not opt_sides == sides.grifball
   and current_player.announced_game_start == 0 and current_player.announce_start_timer.is_zero()
   then 
      send_incident(assault_game_start, current_player, no_player)
      current_player.announced_game_start = 1
      if opt_sides == 1 and current_player.team == team[1] then 
         send_incident(team_offense, current_player, no_player)
      end
      if opt_sides == 1 and current_player.team == team[0] then 
         send_incident(team_defense, current_player, no_player)
      end
   end
end
for each player do -- announce game start (grifball)
   if  opt_sides == sides.grifball
   and current_player.announced_game_start == 0 and current_player.announce_start_timer.is_zero()
   then 
      send_incident(grifball_game_start, current_player, no_player)
      current_player.announced_game_start = 1
   end
end

for each team do -- initial goal setup
   if current_team.has_any_players() and current_team.active_goal == no_object then 
      for each object with label "as_goal" do
         if current_team.has_any_players() and current_team.active_goal == no_object and current_object.team == current_team then 
            alias ally_waypoint_marker = global.object[0]
            --
            -- An object can only have one waypoint with one priority, but we want 
            -- enemies to have a high-priority waypoint on the goal and allies to 
            -- have a low-priority waypoint. The quick workaround is to just create 
            -- a second, invisible, object to host one of the two waypoints.
            --
            -- Since we don't attach the second object, if the goal is a movable 
            -- object, the waypoints will desynch.
            --
            current_team.active_goal = current_object
            current_object.set_shape_visibility(no_one)
            current_object.set_waypoint_visibility(enemies)
            if opt_sides == sides.one_sided and current_team != team[0] then 
               current_object.set_waypoint_visibility(no_one)
            end
            current_object.set_waypoint_icon(destination)
            current_object.set_waypoint_priority(high)
            --
            -- Bungie intended for players to see a low-priority "defend" waypoint 
            -- over their own bomb plant point; however, because they never set the 
            -- team for this marker, it has no "allies" and so its waypoint isn't 
            -- visible to anyone:
            --
            ally_waypoint_marker = no_object
            ally_waypoint_marker = current_object.place_at_me(hill_marker, none, never_garbage_collect, 0, 0, 2, none)
            ally_waypoint_marker.set_waypoint_visibility(allies)
            ally_waypoint_marker.set_waypoint_icon(defend)
            ally_waypoint_marker.set_waypoint_priority(low)
         end
      end
   end
end

for each team do -- enable/disable labeled respawn zones depending on whether the bomb is armed
   alias current_bomb = global.object[0]
   if current_team.has_any_players() then 
      current_bomb = current_team.current_bomb
      if not current_bomb == no_object then 
         for each object with label "as_res_zone" do
            if current_object.team == current_team then 
               current_object.enable_spawn_zone(0)
               current_object.set_shape_visibility(no_one)
               current_object.set_invincibility(1)
               current_object.set_pickup_permissions(no_one)
               if not current_bomb.state == bomb_state.armed then 
                  current_object.enable_spawn_zone(1)
               end
            end
         end
         for each object with label "as_res_zone_away" do
            if current_object.team == current_team then 
               current_object.enable_spawn_zone(0)
               current_object.set_shape_visibility(no_one)
               current_object.set_invincibility(1)
               current_object.set_pickup_permissions(no_one)
               if current_bomb.state == bomb_state.armed then 
                  current_object.enable_spawn_zone(1)
               end
            end
         end
      end
   end
end

for each team do -- initial bomb spawn setup
   if current_team.active_bomb_spawn == no_object then 
      for each object with label "as_bomb" do
         if current_team.active_bomb_spawn == no_object and current_object.team == current_team then 
            current_team.active_bomb_spawn = current_object
         end
      end
   end
end

for each team do -- spawn new bombs as needed
   alias current_bomb  = global.object[0]
   alias new_anti_zone = global.object[1]
   alias need_new_bomb = temp_int_00
   if  current_team == neutral_team
   or  current_team.has_any_players()
   and current_team.current_bomb == no_object
   then 
      need_new_bomb = 0
      if opt_sides == sides.multi and not current_team == neutral_team and current_team.has_any_players() then 
         need_new_bomb = 1
      end
      if opt_sides == sides.one_sided and current_team == team[1] then 
         need_new_bomb = 1
      end
      if opt_sides == sides.neutral or opt_sides == sides.grifball and current_team == neutral_team then 
         need_new_bomb = 1
      end
      if need_new_bomb == 1 then 
         if opt_sides == sides.one_sided or opt_sides == sides.neutral or opt_sides == sides.grifball then
            --
            -- In asymmetric and neutral games, all teams are flagged as sharing a single bomb.
            --
            for each object with label all_bombs do
               current_team.current_bomb = current_object
               need_new_bomb = 0
            end
         end
         if opt_sides == sides.multi then
            alias is_carrying_unowned_bomb = temp_int_01
            for each object with label all_bombs do
               if need_new_bomb == 1 then 
                  is_carrying_unowned_bomb = 1
                  do
                     global.player[0] = no_player
                     global.player[0] = current_object.try_get_carrier()
                     if not global.player[0] == no_player and global.player[0].team == current_team then 
                        is_carrying_unowned_bomb = 1 -- this team is carrying a bomb...
                     end
                  end
                  for each team do
                     if current_team.current_bomb == current_object then
                        is_carrying_unowned_bomb = 0 -- ...but it belongs to any team.
                     end
                  end
                  if is_carrying_unowned_bomb == 1 then
                     --
                     -- If a player is somehow carrying a non-team bomb in Multi Bomb, 
                     -- take ownership of the bomb.
                     --
                     current_team.current_bomb = current_object
                     need_new_bomb = 0
                  end
               end
            end
         end
         if need_new_bomb == 1 then 
            current_team.current_bomb = current_team.active_bomb_spawn.place_at_me(bomb, none, never_garbage_collect, 0, 0, 2, none)
         end
         current_bomb = current_team.current_bomb
         if need_new_bomb == 0 then -- if we took ownership of an existing bomb
            current_bomb.state = 0
         end
         current_team.current_bomb.set_shape(sphere, 10) -- used for sudden death checks
         current_bomb.owner = current_team
         current_team.last_announced_carrier = no_player
         current_bomb.set_pickup_permissions(allies)
         current_bomb.set_weapon_pickup_priority(hold_action)
         if opt_sides == sides.neutral and current_team == neutral_team then 
            current_bomb.set_pickup_permissions(everyone)
         end
         --
         -- Discourage spawning near the bomb:
         --
         new_anti_zone = no_object
         new_anti_zone = current_bomb.place_at_me(respawn_zone_weak_anti, none, never_garbage_collect, 0, 0, 0, none)
         new_anti_zone.team = neutral_team
         new_anti_zone.set_shape(cylinder, 50, 20, 30)
         new_anti_zone.attach_to(current_bomb, 0, 0, 0, absolute)
         current_team.armed_anti_zone = new_anti_zone
         current_team.armed_anti_zone.enable_spawn_zone(0)
         --
         current_bomb.team = current_team
      end
   end
end

for each object with label all_bombs do -- manage bomb waypoint, invincibility, pickup configuration, etc.
   current_object.set_weapon_pickup_priority(hold_action)
   current_object.set_waypoint_icon(bomb)
   current_object.set_waypoint_priority(high)
   current_object.set_waypoint_visibility(everyone)
   do -- bombs should be invincible unless they're armed (so the script can detonate them)
      current_object.set_invincibility(1)
      if current_object.state == bomb_state.armed then 
         current_object.set_invincibility(0)
      end
   end
   if current_object.state != bomb_state.armed then -- allow non-armed bombs to be picked up
      current_object.set_pickup_permissions(allies)
      if opt_sides == sides.grifball or opt_sides == sides.neutral then 
         current_object.set_pickup_permissions(everyone)
      end
   end
end

for each player do -- clear scripted player waypoints
   current_player.biped.set_waypoint_icon(none)
end

for each object with label "as_goal" do
   current_object.set_progress_bar(0, no_one)
   current_object.arm_timer.set_rate(100%)
end

for each team do
   alias current_bomb    = global.object[0]
   alias current_carrier = global.player[0]
   alias plant_point     = global.object[1]
   --
   current_bomb    = current_team.current_bomb
   current_carrier = no_player
   current_carrier = current_bomb.try_get_carrier()
   if not current_carrier == no_player then -- handle the bomb being carried
      alias carrier_team  = temp_tem_00
      alias defender_team = temp_tem_01
      --
      current_bomb.set_waypoint_visibility(no_one)
      current_carrier.biped.set_waypoint_icon(bomb)
      current_bomb.arm_timer.set_rate(0%)
      if not opt_arm_time == 0 then 
         current_bomb.arm_timer.set_rate(100%)
      end
      current_bomb.reset_timer  = opt_reset_time
      current_carrier.apply_traits(carrier_traits)
      current_team.last_carrier = current_carrier
      do
         current_carrier.carry_time_update_interval.set_rate(-100%)
         if current_carrier.carry_time_update_interval.is_zero() then 
            current_carrier.carry_time += 1
            current_carrier.carry_time_update_interval.reset()
         end
      end
      carrier_team = current_carrier.team
      plant_point = no_object
      for each object with label "as_goal" do -- find a plant point to arm
         current_object.arm_timer.set_rate(0%)
         defender_team = current_object.team
         if  defender_team.has_any_players()
         and current_object.shape_contains(current_carrier.biped)
         and not carrier_team.active_goal.shape_contains(current_carrier.biped) -- if attacker and defender goals overlap, attacker cannot arm while standing in the area of overlap
         then 
            plant_point = current_object
         end
      end
      if not plant_point == no_object then -- arming
         plant_point.arm_timer = current_bomb.arm_timer
         plant_point.set_progress_bar(object.arm_timer, mod_player, current_carrier, 1)
         plant_point.arm_timer.set_rate(-100%)
         ui_you_arming.set_visibility(current_carrier, true)
         do
            defender_team = plant_point.team
            if defender_team.has_any_players() then -- redundant! >:(
               for each player do
                  ui_foe_arming.set_visibility(current_player, false)
                  if current_player.team == defender_team then 
                     ui_foe_arming.set_visibility(current_player, true)
                  end
               end
            end
         end
         current_bomb.arm_timer.set_rate(-100%)
         current_team.last_carrier = current_carrier
         if plant_point.arm_timer.is_zero() then
            send_incident(bomb_armed, current_carrier, all_players)
            send_incident(bomb_planted, current_carrier, all_players)
            current_team.last_announced_carrier = no_player
            current_carrier.bombs_planted += 1
            current_bomb.state = bomb_state.armed
            current_bomb.disarm_timer = opt_disarm_time
            current_bomb.detach() -- force the bomb's carrier to drop it
            current_bomb.attach_to(plant_point, 0, 0, 2, absolute)
            current_bomb.planted_on = plant_point
            current_bomb.set_pickup_permissions(no_one)
            current_bomb.set_progress_bar(object.disarm_timer, enemies)
            plant_point.set_progress_bar(0, no_one)
            current_bomb.set_waypoint_timer(3)
            current_bomb.fuse_timer.set_rate(-100%)
            current_bomb.team = current_carrier.team
         end
      end
   end
   if current_carrier == no_player and current_bomb.state == bomb_state.carried then -- state: carried -> dropped
      temp_tem_00 = current_bomb.team
      current_bomb.state = bomb_state.dropped
      global.player[1] = temp_tem_00.last_carrier
      global.player[1].carrier_cooldown_timer = opt_carrier_cooldown
      current_bomb.arm_timer.reset()
      if opt_arm_time == 0 then 
         current_bomb.arm_timer.set_rate(0%)
      end
      if opt_sides == sides.neutral or opt_sides == sides.grifball then 
         current_bomb.team = neutral_team
      end
   end
end

for each object with label all_bombs do
   alias current_bomb = global.object[0]
   --
   current_bomb = current_object
   if current_object.state == bomb_state.armed then 
      current_bomb.fuse_timer.set_rate(-100%)
      if current_object.planted_on == no_object then 
         for each object with label "as_goal" do
            if current_bomb.shape_contains(current_object) then 
               current_bomb.planted_on = current_object
            end
         end
      end
   end
end

for each team do -- bomb detonation
   alias current_bomb = global.object[0]
   alias bomb_owner   = temp_tem_00
   --
   current_bomb = current_team.current_bomb
   bomb_owner   = current_bomb.team
   if  not current_bomb == no_object
   and not current_team.last_carrier == no_player
   and current_bomb.state == bomb_state.armed
   and current_bomb.fuse_timer.is_zero()
   then 
      send_incident(bomb_detonated, current_bomb.team, current_team)
      current_bomb.set_invincibility(0)
      current_bomb.kill(false)
      current_team.last_carrier.score += 1
      global.player[0] = current_team.last_carrier
      global.player[0].detonations += 1
      if not global.player[0].team == bomb_owner then
         --
         -- The player who planted this bomb is no longer on the bomb's team. 
         -- This can occur if players change teams during a match. Revert the 
         -- changes we made to the individual player's score and stats, and 
         -- give the team itself one point.
         --
         current_team.last_carrier.score -= 1
         bomb_owner.score += 1
         global.player[0].detonations -= 1
      end
   end
end

for each team do -- handle bomb disarming
   alias current_bomb = global.object[0]
   --
   current_bomb = current_team.current_bomb
   if not current_bomb == no_object and current_bomb.state == bomb_state.armed then 
      current_bomb.disarm_timer.set_rate(100%) -- disarm time should regenerate if no one is disarming
      current_bomb.set_progress_bar(0, no_one)
      --
      for each player do -- identify disarming players
         current_player.is_disarming = 0
         if  not opt_disarm_time == -1 -- if disarming isn't disabled
         and not current_player.team == current_team
         and current_player.team != current_bomb.team
         and current_bomb.shape_contains(current_player.biped)
         then
            alias player_allowed_to_disarm = temp_int_00
            --
            player_allowed_to_disarm = 1
            global.object[1] = current_bomb.planted_on
            if current_bomb.state == bomb_state.armed and global.object[1].team != current_player.team then
               --
               -- You cannot disarm bombs that have been planted on a different team's 
               -- plant point; you can only disarm bombs that have been planted on your 
               -- own team's plant point.
               --
               player_allowed_to_disarm = 0
            end
            if player_allowed_to_disarm == 1 then 
               current_player.is_disarming = 1
               if opt_disarm_time != 0 then -- if disarming isn't instant
                  current_bomb.disarm_timer.set_rate(-100%)
                  ui_disarming.set_visibility(current_player, true)
                  current_bomb.set_progress_bar(object.disarm_timer, enemies)
               end
            end
         end
      end
      --
      alias disarm_complete = temp_int_00
      --
      disarm_complete = 0
      if opt_disarm_time != 0 and current_bomb.disarm_timer.is_zero() then 
         disarm_complete = 1
      end
      if opt_disarm_time == 0 then -- instant disarm
         for each player do
            if current_player.is_disarming == 1 then 
               disarm_complete = 1
            end
         end
      end
      if disarm_complete == 1 then 
         if current_bomb.state == bomb_state.armed then 
            send_incident(bomb_disarmed, all_players, all_players)
         end
         for each player do
            if current_player.is_disarming == 1 then 
               current_player.defuses += 1
               current_player.is_disarming = 0
            end
         end
         current_bomb.state = bomb_state.dropped
         current_bomb.disarm_timer.reset()
         current_bomb.arm_timer.reset()
         current_bomb.fuse_timer.reset()
         current_bomb.disarm_timer.set_rate(0%)
         current_bomb.arm_timer.set_rate(0%)
         current_bomb.fuse_timer.set_rate(0%)
         current_bomb.set_waypoint_timer(none)
         current_bomb.set_progress_bar(0, no_one)
         current_bomb.detach()
         current_bomb.set_pickup_permissions(allies)
         current_bomb.team = current_bomb.owner
         if opt_sides == sides.neutral and current_team == neutral_team then 
            current_bomb.set_pickup_permissions(everyone)
         end
         if opt_reset_on_disarm == 1 then 
            current_bomb.delete() -- deleting the bomb resets it
         end
      end
   end
end

for each team do -- bomb reset (timer)
   alias current_bomb = global.object[0]
   --
   current_bomb = current_team.current_bomb
   if not current_bomb == no_object and current_bomb.state == bomb_state.dropped then 
      do
         current_bomb.reset_timer.set_rate(-100%)
         if current_bomb.reset_timer < 6 then -- blink the bomb's waypoint when it's close to resetting
            current_bomb.set_waypoint_priority(blink)
         end
      end
      if current_bomb.reset_timer.is_zero() or current_bomb.is_out_of_bounds() then 
         send_incident(bomb_reset_neutral, all_players, all_players)
         current_bomb.delete()
      end
   end
end

for each team do -- bomb reset (out of bounds)
   global.object[0] = current_team.current_bomb
   if not global.object[0] == no_object and global.object[0].is_out_of_bounds() then 
      if opt_sides == sides.neutral then 
         send_incident(bomb_reset_neutral, all_players, all_players)
      end
      if not opt_sides == sides.neutral then 
         send_incident(bomb_reset, current_team, all_players)
      end
      global.object[0].delete()
   end
end

for each player do -- bomb carrier cooldown traits
   global.object[0] = current_player.biped
   if not global.object[0] == no_object then -- only apply traits if the player is alive
      global.object[1] = no_object
      global.object[1] = current_player.try_get_weapon(primary)
      if not global.object[1].is_of_type(bomb) and current_player.carrier_cooldown_timer > 0 then 
         current_player.carrier_cooldown_timer.set_rate(-100%)
         if not current_player.carrier_cooldown_timer.is_zero() then 
            current_player.apply_traits(cooldown_traits)
         end
      end
   end
end

if opt_sides == sides.grifball then -- Grifball: delete dropped Energy Swords and Gravity Hammers
   for each player do
      if current_player.killer_type_is(guardians | suicide | kill | betrayal | quit) then 
         for each object with label all_hammers do
            global.player[0] = no_player
            global.player[0] = current_object.try_get_carrier()
            if global.player[0] == no_player then 
               current_object.abandoned = 1
            end
         end
         for each object with label all_swords do
            global.player[0] = no_player
            global.player[0] = current_object.try_get_carrier()
            if global.player[0] == no_player then 
               current_object.abandoned = 1
            end
         end
      end
   end
   for each object with label all_hammers do
      if current_object.abandoned == 1 then 
         current_object.delete()
      end
   end
   for each object with label all_swords do
      if current_object.abandoned == 1 then 
         current_object.delete()
      end
   end
end

for each team do -- detect if the bomb carrier is killed or drops the bomb
   alias killer       = global.player[0]
   alias current_bomb = global.object[0]
   if current_team.has_any_players() then 
      killer = no_player
      current_bomb = current_team.current_bomb
      if current_team.last_carrier.killer_type_is(kill) then 
         killer = current_team.last_carrier.try_get_killer()
         send_incident(bomb_carrier_kill, killer, current_team.last_carrier)
         if current_bomb.state != bomb_state.armed then 
            current_team.last_carrier = no_player
         end
      end
      if current_team.last_carrier != no_player then 
         global.object[1] = current_team.current_bomb
         global.player[1] = no_player
         for each player do
            if current_player == current_team.last_carrier then 
               global.player[1] = current_bomb.try_get_carrier()
               if global.player[1] == no_player and current_bomb.state != bomb_state.armed then 
                  current_team.last_carrier = no_player
               end
            end
         end
      end
   end
end

for each object with label all_bombs do -- set bomb_state.carried when appropriate
   if current_object.state != bomb_state.carried then 
      global.player[0] = no_player
      global.player[0] = current_object.try_get_carrier()
      if not global.player[0] == no_player then 
         current_object.state = bomb_state.carried
      end
   end
end

for each team do -- announce bomb taken/dropped
   alias current_carrier = global.player[0]
   --
   current_team.announce_juggle_cooldown.set_rate(-100%)
   if current_team.announce_juggle_cooldown.is_zero() then 
      current_carrier = no_player
      current_carrier = current_team.current_bomb.try_get_carrier()
      if current_carrier == no_player and current_team.last_announced_carrier != no_player then 
         send_incident(bomb_dropped, current_team.last_announced_carrier, all_players)
         current_team.last_announced_carrier = no_player
         current_team.announce_juggle_cooldown.reset()
      end
      if current_carrier != no_player and current_carrier != current_team.last_announced_carrier then 
         send_incident(bomb_taken, current_carrier, current_carrier.team)
         current_team.last_announced_carrier = current_carrier
         current_team.announce_juggle_cooldown.reset()
      end
   end
end

for each team do -- when a bomb is armed, discourage spawning around it
   if current_team.current_bomb != no_object then 
      global.object[0] = current_team.current_bomb
      current_team.armed_anti_zone.enable_spawn_zone(0)
      if global.object[0].state == bomb_state.armed then 
         current_team.armed_anti_zone.enable_spawn_zone(1)
      end
   end
end

do -- manage Sudden Death
   alias current_bomb  = global.object[0]
   alias should_enable = temp_int_00
   --
   should_enable = 0
   sudden_death_enabled = 0
   for each team do
      if current_team == neutral_team or current_team.has_any_players() then 
         current_bomb = current_team.current_bomb
         if  current_bomb != no_object
         and current_bomb.state != bomb_state.dropped
         and current_bomb.state != bomb_state.initial
         then 
            should_enable = 1
         end
      end
   end
   if should_enable == 1 then 
      sudden_death_enabled = 1
   end
end

-- Round timer management:
if not game.round_timer.is_zero() then 
   game.grace_period_timer = 0
end
if game.round_time_limit > 0 then 
   if not game.round_timer.is_zero() then 
      announced_sudden_death = 0
   end
   if game.round_timer.is_zero() then 
      if sudden_death_enabled == 1 then 
         game.sudden_death_timer.set_rate(-100%)
         game.grace_period_timer.reset()
         if announced_sudden_death == 0 then 
            send_incident(sudden_death, all_players, all_players)
            announced_sudden_death = 1
         end
         if game.sudden_death_time > 0 and game.grace_period_timer > game.sudden_death_timer then 
            game.grace_period_timer = game.sudden_death_timer
         end
      end
      if sudden_death_enabled == 0 then 
         game.grace_period_timer.set_rate(-100%)
         if game.grace_period_timer.is_zero() then 
            game.end_round()
         end
      end
      if game.sudden_death_timer.is_zero() then 
         game.end_round()
      end
   end
end
