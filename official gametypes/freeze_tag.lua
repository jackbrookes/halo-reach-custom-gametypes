
-- Forge labels:
alias all_jetpacks       = 0
alias all_armor_locks    = 1
alias all_flags          = 7
alias all_health_packs   = 8
alias all_fire_particles = 9
alias all_sound_emitters = 10 -- unused

alias carrier_traits     = script_traits[0]
alias frozen_traits_red  = script_traits[1]
alias frozen_traits_blue = script_traits[2]
alias sweater_traits     = script_traits[3]
alias last_man_traits    = script_traits[4]
alias chilled_traits     = script_traits[5]
alias frosty_traits      = script_traits[6]

alias opt_thaw_time    = script_option[0]
alias opt_sweater_time = script_option[1]
alias opt_ctf_enabled  = script_option[2]
alias opt_flag_delay   = script_option[3]
alias opt_flag_reset   = script_option[4]

alias flag_captures = player.script_stat[0]

alias in_sudden_death        = global.number[0]
alias announced_sudden_death = global.number[1]
alias swapped_flag_return_point_ownership = global.number[6] -- IIRC Freeze Tag has Assault-ish gameplay but uses CTF labels, so it needs to swap ownership for all flag return points
alias displayed_flag_spawn_advance_notice = global.number[7]
alias announced_ctf_start                 = global.number[8]
alias red_team          = global.team[0]
alias blue_team         = global.team[1]
alias flag_delay_timer  = global.timer[0]
alias loadout_cam_timer = global.timer[1]
alias last_man_delay    = global.timer[2] -- a player cannot attain last man standing status sooner than (loadout cam time + this)
alias away_state         = object.number[0] -- for flags
alias away_state_at_home = 0
alias away_state_carried = 1
alias away_state_dropped = 2
alias ownership_swapped     = object.number[1] -- for teams' flag return points
alias announced_flag_take   = object.number[3]
alias announced_flag_drop   = object.number[4]
alias current_carrier       = object.player[0]
alias reset_timer           = object.timer[0] -- for flags
alias lifespan              = object.timer[1] -- used to delete fire particle emitters
alias notification_throttle = object.timer[2] -- used to avoid "FLAG TAKEN. FLAG DROPPED. FLAG TAKEN. FLAG DROPPED."
alias ach_top_shot_count        = player.number[0]
alias ach_license_to_kill_count = player.number[1]
alias freeze_state              = player.number[3]
alias freeze_state_none    = 0
alias freeze_state_partial = 1
alias freeze_state_almost  = 2
alias freeze_state_frozen  = 3
alias freeze_state_sweater = 4
alias is_last_man     = player.number[4]
alias being_thawed_by = player.player[0]
alias ach_paper_beats_rock_vuln_timer = player.timer[0]
alias thaw_timer    = player.timer[2]
alias sweater_timer = player.timer[3]
alias player_count         = team.number[0] -- number of players on a team that have a biped
alias frozen_player_count  = team.number[1]
alias flag_return_point    = team.object[0] -- for neutral_team, this is also the Neutral Flag spawn point
alias owned_flag           = team.object[1]
alias last_man_standing    = team.player[0]
alias thaw_notify_throttle = team.timer[0]

alias announce_start_timer = player.timer[1]
alias announced_game_start = player.number[2]

declare in_sudden_death        with network priority local
declare announced_sudden_death with network priority local
declare global.number[2] with network priority local -- temporary
declare global.number[3] with network priority low
declare global.number[4] with network priority low
declare global.number[5] with network priority low
declare swapped_flag_return_point_ownership with network priority low
declare displayed_flag_spawn_advance_notice with network priority low
declare announced_ctf_start with network priority low
declare global.number[9] with network priority local
declare global.number[10] with network priority local
declare global.object[0] with network priority local
declare global.object[1] with network priority local
declare global.player[0] with network priority local
declare global.player[1] with network priority local
declare red_team  with network priority high = team[0]
declare blue_team with network priority high = team[1]
declare global.team[2] with network priority local
declare flag_delay_timer  = opt_flag_delay
declare loadout_cam_timer = game.loadout_cam_time
declare last_man_delay    = 3
declare player.ach_top_shot_count        with network priority low
declare player.ach_license_to_kill_count with network priority low
declare player.announced_game_start      with network priority low
declare player.freeze_state              with network priority low
declare player.is_last_man               with network priority low
declare player.object[0] with network priority low
declare player.object[1] with network priority low
declare player.being_thawed_by with network priority low
declare player.announce_start_timer = 5
declare player.thaw_timer    = opt_thaw_time
declare player.sweater_timer = opt_sweater_time
declare object.away_state          with network priority low
declare object.ownership_swapped   with network priority low
declare object.number[2]           with network priority low = 1
declare object.announced_flag_take with network priority local
declare object.announced_flag_drop with network priority local
declare object.object[0]           with network priority low
declare object.current_carrier     with network priority low
declare object.reset_timer = opt_flag_reset
declare object.lifespan = 1
declare object.notification_throttle = 3
declare team.player_count        with network priority low
declare team.frozen_player_count with network priority low
declare team.flag_return_point   with network priority low
declare team.owned_flag          with network priority low
declare team.last_man_standing   with network priority low
declare team.thaw_notify_throttle = 2

do
   in_sudden_death = 0
end

for each player do -- award Dive Bomber achievement as appropriate
   if current_player.killer_type_is(kill) then 
      alias killer    = global.player[0]
      alias killer_aa = global.object[0]
      --
      killer = no_player
      killer = current_player.try_get_killer()
      global.number[2] = 0
      global.number[2] = current_player.try_get_death_damage_mod()
      if global.number[2] == enums.damage_reporting_modifier.assassination then -- beatdown i.e. punching an enemy in the back
         killer_aa = no_object
         killer_aa = killer.try_get_armor_ability()
         if killer_aa.has_forge_label(all_jetpacks) and killer_aa.is_in_use() then 
            send_incident(dlc_achieve_2, killer, killer, 65)
         end
      end
   end
end

for each player do -- award From Hell's Heart achievement as appropriate
   if current_player.killer_type_is(kill) then 
      global.number[2] = 0
      global.number[2] = current_player.try_get_death_damage_mod()
      if global.number[2] == enums.damage_reporting_modifier.sticky then -- sticky grenade
         global.player[0] = no_player
         global.player[0] = current_player.try_get_killer()
         if global.player[0].killer_type_is(suicide) then 
            send_incident(dlc_achieve_2, current_player, current_player, 68)
         end
      end
   end
end

for each player do -- manage and award Top Shot achievement as appropriate
   if current_player.killer_type_is(guardians | suicide | kill | betrayal | quit) then 
      current_player.ach_top_shot_count = 0
      if current_player.killer_type_is(kill) then
         alias killer = global.player[0]
         --
         killer = no_player
         killer = current_player.try_get_killer()
         global.number[2] = 0
         global.number[2] = current_player.try_get_death_damage_mod()
         if global.number[2] != enums.damage_reporting_modifier.headshot then -- if not headshot
            killer.ach_top_shot_count = 0
         end
         if global.number[2] == enums.damage_reporting_modifier.headshot then -- if headshot
            killer.ach_top_shot_count += 1
         end
         if killer.ach_top_shot_count > 2 then 
            send_incident(dlc_achieve_2, killer, killer, 62)
         end
      end
   end
end

for each player do -- manage and award License To Kill achievement as appropriate
   if current_player.killer_type_is(kill) then 
      global.player[0] = no_player
      global.player[0] = current_player.try_get_killer()
      global.number[2] = 0
      global.number[2] = current_player.try_get_death_damage_mod()
      if global.number[2] == enums.damage_reporting_modifier.splatter then -- splatter
         global.player[0].ach_license_to_kill_count += 1
      end
      if global.player[0].ach_license_to_kill_count > 4 then 
         send_incident(dlc_achieve_2, global.player[0], global.player[0], 66)
      end
   end
end

for each player do -- manage timing for the Paper Beats Rock achievement
   alias current_ability = global.object[0]
   --
   current_ability = no_object
   current_ability = current_player.try_get_armor_ability()
   if current_ability.has_forge_label(all_armor_locks) and current_ability.is_in_use() then 
      current_player.ach_paper_beats_rock_vuln_timer = 3
      current_player.ach_paper_beats_rock_vuln_timer.set_rate(-100%)
   end
end
for each player do -- award Paper Beats Rock achievement as appropriate
   if current_player.killer_type_is(kill) and not current_player.ach_paper_beats_rock_vuln_timer.is_zero() then 
      global.number[2] = 0
      global.number[2] = current_player.try_get_death_damage_mod()
      if global.number[2] == enums.damage_reporting_modifier.assassination then 
         global.player[0] = no_player
         global.player[0] = current_player.try_get_killer()
         send_incident(dlc_achieve_2, global.player[0], global.player[0], 60)
      end
   end
end

on pregame: do
   game.symmetry = 1
end

for each player do -- manage loadout palettes
   if current_player.is_elite() then 
      current_player.set_loadout_palette(elite_tier_1)
   end
   if not current_player.is_elite() then 
      current_player.set_loadout_palette(spartan_tier_1)
   end
end

on init: do
   loadout_cam_timer.reset()
   --
   -- We need to know which team is red and which team is blue, so we can apply the 
   -- appropriate visuals to players that are frozen. However, that's trickier than 
   -- you might expect: teams alternate each round, but their indices are remapped. 
   -- On round 1, Red Team is team[0], but on round 2, it's team[1].
   --
   global.number[2] = game.current_round
   global.number[2] %= 2
   if global.number[2] == 0 then 
      red_team  = team[0]
      blue_team = team[1]
   end
   if global.number[2] != 0 then 
      red_team  = team[1]
      blue_team = team[0]
   end
end

for each player do -- UI setup, round card text, and announce game start
   current_player.announce_start_timer.set_rate(-100%)
   loadout_cam_timer.set_rate(-100%)
   for each team do
      current_team.thaw_notify_throttle.set_rate(-100%)
   end
   script_widget[1].set_visibility(current_player, false)
   script_widget[0].set_visibility(current_player, false)
   script_widget[2].set_visibility(current_player, false)
   script_widget[1].set_text("Red Players Frozen: %n / %n",  red_team.frozen_player_count,  red_team.player_count)
   script_widget[0].set_text("Blue Players Frozen: %n / %n", blue_team.frozen_player_count, blue_team.player_count)
   script_widget[2].set_text("Thawing: %s", hud_player.thaw_timer)
   if opt_ctf_enabled == 0 then 
      current_player.set_round_card_title("Freeze all opposing players to win.")
   end
   if opt_ctf_enabled == 1 then 
      current_player.set_round_card_title("Freeze all opposing players or push \nthe neutral flag into the enemy \nbase to win.")
   end
   script_widget[1].set_visibility(current_player, true)
   script_widget[0].set_visibility(current_player, true)
   if current_player.announced_game_start == 0 and current_player.announce_start_timer.is_zero() then 
      send_incident(action_sack_game_start, current_player, no_player)
      current_player.announced_game_start = 1
   end
end

do -- delete all health packs
   for each object with label all_health_packs do
      current_object.delete()
   end
end

-- Notify players at most ten seconds before CTF begins:
if opt_ctf_enabled == 1 and opt_flag_delay > 1 and displayed_flag_spawn_advance_notice == 0 and flag_delay_timer < 11 then 
   game.show_message_to(all_players, timer_beep, "Flag spawns in %s", flag_delay_timer)
   displayed_flag_spawn_advance_notice = 1
end

do
   if loadout_cam_timer.is_zero() then 
      last_man_delay.set_rate(-100%)
   end
   if opt_ctf_enabled == 1 then 
      if loadout_cam_timer.is_zero() then 
         flag_delay_timer.set_rate(-100%)
      end
      if swapped_flag_return_point_ownership == 0 then 
         for each object with label "ctf_flag_return" do
            if current_object.ownership_swapped == 0 and current_object.team == team[1] then 
               current_object.team = team[0]
               current_object.ownership_swapped = 1
            end
         end
         for each object with label "ctf_flag_return" do
            if current_object.ownership_swapped == 0 and current_object.team == team[0] then 
               current_object.team = team[1]
               current_object.ownership_swapped = 1
            end
         end
         swapped_flag_return_point_ownership = 1
      end
   end
end

for each team do -- give teams a waypoint on their capture points, once CTF begins
   if opt_ctf_enabled == 1 and flag_delay_timer.is_zero() and current_team.flag_return_point == no_object then 
      for each object with label "ctf_flag_return" do
         if current_team.flag_return_point == no_object and current_object.team == current_team then 
            current_team.flag_return_point = current_object
            current_object.set_waypoint_visibility(allies)
            current_object.set_waypoint_icon(destination)
         end
      end
   end
end

for each team do -- spawn flags and set some basic properties
   if opt_ctf_enabled == 1 and flag_delay_timer.is_zero() then 
      current_team.owned_flag.set_waypoint_visibility(everyone)
      --
      if  current_team == neutral_team
      or  current_team.has_any_players()
      and current_team.owned_flag == no_object
      and not current_team.flag_return_point == no_object
      then
         alias should_spawn_flag = global.number[2]
         --
         should_spawn_flag = 0
         if current_team == neutral_team then 
            should_spawn_flag = 1
         end
         if should_spawn_flag == 1 then 
            do -- if any flag already exists on the map, use it instead
               for each object do
                  if current_object.is_of_type(flag) then 
                     current_team.owned_flag = current_object
                     should_spawn_flag = 0
                  end
               end
            end
            if should_spawn_flag == 1 then 
               current_team.owned_flag = current_team.flag_return_point.place_at_me(flag, none, never_garbage_collect, 0, 0, 3, none)
               if opt_flag_delay > 1 and announced_ctf_start == 0 then 
                  game.show_message_to(all_players, announce_ctf, "Capture the Flag")
                  announced_ctf_start = 1
               end
            end
            --
            alias current_flag = global.object[0]
            --
            current_flag = current_team.owned_flag
            if should_spawn_flag == 0 then 
               current_flag.away_state = away_state_carried
            end
            current_flag.team = current_team
            current_team.owned_flag.set_weapon_pickup_priority(hold_action)
            current_team.owned_flag.set_waypoint_icon(flag)
            current_team.owned_flag.set_waypoint_priority(high)
            current_flag.set_shape(cylinder, 7, 6, 3)
            if current_team == neutral_team then 
               current_team.owned_flag.set_pickup_permissions(everyone)
            end
         end
      end
   end
end

for each team do -- manage team living player count
   if current_team.has_any_players() then
      alias count = global.number[2]
      --
      count = 0
      for each player do
         global.object[0] = current_player.biped
         if global.object[0] != no_object and current_player.team == current_team then 
            count += 1
         end
      end
      current_team.player_count = count
   end
end

for each player do -- unfreeze players when they die
   if current_player.killer_type_is(guardians | suicide | kill | betrayal | quit) then 
      current_player.freeze_state = freeze_state_none
      current_player.biped.set_shape(none)
      current_player.thaw_timer.reset()
   end
end

for each player do -- manage players returning to normal after sweater traits
   global.object[0] = current_player.biped
   if  global.object[0] != no_object
   and current_player.freeze_state == freeze_state_sweater
   and current_player.sweater_timer.is_zero()
   then 
      global.player[0] = current_player
      current_player.freeze_state = freeze_state_none
      global.object[1] = no_object
      global.object[1] = current_player.try_get_weapon(primary)
      if global.object[1] == no_object then 
         global.player[0].biped.add_weapon(focus_rifle, force)
      end
      if global.player[0].object[0] == neutral_team.object[1] then 
         current_player.object[0].set_pickup_permissions(mod_player, current_player, 1)
      end
   end
end

for each player do -- move player to freeze_state_none when appropriate
   global.object[0] = current_player.biped
   if  global.object[0] != no_object
   and current_player.freeze_state != freeze_state_none
   and current_player.freeze_state != freeze_state_sweater
   then 
      global.number[2] = 0
      global.number[2] = current_player.biped.shields
      if global.number[2] > 66 then 
         global.team[2] = current_player.team
         current_player.freeze_state = freeze_state_none
      end
   end
end
for each player do -- move player to freeze_state_partial when appropriate
   global.object[0] = current_player.biped
   if global.object[0] != no_object and current_player.freeze_state != freeze_state_partial then 
      global.number[2] = 0
      global.number[2] = current_player.biped.shields
      if global.number[2] <= 66 and global.number[2] > 33 then 
         current_player.freeze_state = freeze_state_partial
         game.show_message_to(current_player, none, "You're partially frozen!")
      end
   end
end
for each player do -- move player to freeze_state_almost when appropriate
   global.object[0] = current_player.biped
   if global.object[0] != no_object and current_player.freeze_state != freeze_state_almost then 
      global.number[2] = 0
      global.number[2] = current_player.biped.shields
      if global.number[2] <= 33 and global.number[2] > 0 then 
         current_player.freeze_state = freeze_state_almost
         game.show_message_to(current_player, none, "You're almost frozen!")
      end
   end
end
for each player do -- move player to freeze_state_frozen when appropriate
   global.object[0] = current_player.biped
   if global.object[0] != no_object and current_player.freeze_state != freeze_state_frozen then 
      global.number[2] = 0
      global.number[2] = current_player.biped.shields
      if global.number[2] <= 0 then 
         global.player[0] = current_player
         global.player[0].freeze_state = freeze_state_frozen
         global.player[0].thaw_timer.reset()
         global.player[0].thaw_timer.set_rate(-100%)
         current_player.object[1] = current_player.try_get_weapon(secondary)
         if current_player.object[1] != no_object then 
            current_player.object[1].set_pickup_permissions(mod_player, current_player, 0)
            current_player.biped.remove_weapon(primary, false)
            if current_player.object[1] != neutral_team.object[1] then 
               current_player.object[1].delete()
            end
         end
         current_player.object[0] = current_player.try_get_weapon(primary)
         if current_player.object[0] != no_object then 
            current_player.object[0].set_pickup_permissions(mod_player, current_player, 0)
            current_player.biped.remove_weapon(secondary, false)
            if current_player.object[0] != neutral_team.object[1] then 
               current_player.object[0].delete()
            end
         end
         global.team[2] = global.player[0].team
         game.show_message_to(global.team[2], none, "%p is frozen!", global.player[0])
         global.player[0].biped.set_shape(cylinder, 8, 8, 4)
      end
   end
end

for each player do -- apply sweater traits and handle vfx
   if current_player.freeze_state == freeze_state_sweater and not current_player.sweater_timer.is_zero() then 
      current_player.apply_traits(sweater_traits) -- applied after a player is thawed
      global.number[2] = 0
      global.number[2] = rand(10)
      if global.number[2] <= 2 then -- 30% chance of dropping a fire emitter every 1/60 seconds
         current_player.biped.place_at_me(particle_emitter_fire, none, never_garbage_collect, 0, 0, 0, none)
      end
   end
end
for each player do -- apply chilled traits
   if current_player.freeze_state == freeze_state_partial then 
      current_player.apply_traits(chilled_traits)
   end
end
for each player do -- apply frosty traits
   if current_player.freeze_state == freeze_state_almost then 
      current_player.apply_traits(frosty_traits)
   end
end

for each player do -- handle frozen traits and UI
   if current_player.freeze_state == freeze_state_frozen and not current_player.thaw_timer.is_zero() then 
      global.player[0] = current_player
      if global.player[0].team == red_team then 
         global.player[0].apply_traits(frozen_traits_red)
      end
      if global.player[0].team == blue_team then 
         global.player[0].apply_traits(frozen_traits_blue)
      end
      global.player[0].biped.set_waypoint_visibility(allies)
      global.player[0].biped.set_waypoint_priority(normal)
      global.player[0].biped.set_waypoint_text("FROZEN ALLY!")
      global.player[0].biped.set_waypoint_icon(vip)
      script_widget[2].set_visibility(global.player[0], true)
   end
end

for each player do -- apply last man traits
   if current_player.is_last_man == 1 then 
      current_player.apply_traits(last_man_traits)
   end
end

for each player do -- manage visibility of frozen player shape boundaries
   if current_player.freeze_state == freeze_state_frozen then 
      global.player[0] = current_player
      global.player[0].biped.set_shape_visibility(mod_player, global.player[0], 1)
      for each player do -- don't allow enemies or frozen allies to see this player's shape
         if current_player != global.player[0] and current_player.team == global.player[0].team and current_player.freeze_state == freeze_state_frozen then 
            current_player.biped.set_shape_visibility(mod_player, global.player[0], 0)
         end
      end
   end
   if current_player.freeze_state != freeze_state_frozen then 
      global.player[0] = current_player
      for each player do -- reveal frozen allies' shapes
         if current_player != global.player[0] and current_player.team == global.player[0].team and current_player.freeze_state == freeze_state_frozen then 
            current_player.biped.set_shape_visibility(mod_player, global.player[0], 1)
         end
      end
   end
end

for each object with label all_fire_particles do -- delete fire particles after a short time
   current_object.lifespan.set_rate(-100%)
   if current_object.lifespan.is_zero() then 
      current_object.delete()
   end
end

for each player do -- detect when a frozen player stops being thawed by an ally
   if current_player.freeze_state == freeze_state_frozen and current_player.being_thawed_by != no_player then 
      global.player[0] = current_player
      if not global.player[0].biped.shape_contains(global.player[0].being_thawed_by.biped) then 
         global.player[0].being_thawed_by = no_player
         global.player[0].thaw_timer.set_rate(-100%)
         global.player[0].biped.set_waypoint_priority(high)
      end
   end
end
for each player do -- detect when a frozen player starts being thawed by an ally
   if current_player.freeze_state == freeze_state_frozen then
      alias thawee    = global.player[0]
      alias thawer    = global.player[1]
      alias ally_team = global.team[2]
      --
      thawee    = current_player
      ally_team = thawee.team
      if thawee.being_thawed_by == no_player then 
         for each player do
            if thawee.being_thawed_by == no_player and current_player != thawee and thawee.biped.shape_contains(current_player.biped) then 
               thawer = current_player
               if thawer.freeze_state != freeze_state_frozen and thawer.team == ally_team then 
                  thawee.being_thawed_by = thawer
                  if ally_team.thaw_notify_throttle.is_zero() then 
                     game.show_message_to(ally_team, timer_beep, "%p is thawing %p!", thawer, thawee)
                     ally_team.thaw_notify_throttle.reset()
                  end
               end
            end
         end
      end
   end
end

for each player do -- frozen players being thawed by an ally should thaw faster and blink their waypoints
   if current_player.freeze_state == freeze_state_frozen and current_player.being_thawed_by != no_player then 
      global.player[0] = current_player
      global.player[0].thaw_timer.set_rate(-400%)
      global.player[0].biped.set_waypoint_priority(blink)
   end
end
for each player do -- frozen players who are six seconds or less from thawing should blink their waypoints
   if current_player.freeze_state == freeze_state_frozen then 
      global.player[0] = current_player
      if global.player[0].thaw_timer < 6 then 
         global.player[0].biped.set_waypoint_priority(blink)
      end
   end
end

for each player do -- handle thawing out a player
   if current_player.freeze_state == freeze_state_frozen then 
      global.player[0] = current_player
      global.team[2]   = global.player[0].team
      if global.player[0].thaw_timer.is_zero() then 
         script_widget[2].set_visibility(global.player[0], false)
         global.player[0].biped.shields = 100
         global.player[0].sweater_timer.reset()
         global.player[0].sweater_timer.set_rate(-100%)
         global.player[0].freeze_state = freeze_state_sweater
         global.player[0].biped.set_shape(none)
         game.show_message_to(global.player[0], none, "Thawed! Find cover!")
      end
   end
end

for each team do -- manage team frozen player count
   if current_team.has_any_players() then
      alias count = global.number[2]
      --
      count = 0
      for each player do
         if current_player.team == current_team then 
            if current_player.freeze_state == freeze_state_frozen then 
               count += 1
            end
         end
      end
      current_team.frozen_player_count = count
   end
end

for each team do -- grant last man standing status
   if current_team.has_any_players() and loadout_cam_timer.is_zero() and last_man_delay.is_zero() then 
      global.number[2] = current_team.player_count
      global.number[2] -= 1
      if global.number[2] == current_team.frozen_player_count then
         --
         -- All but one of this team's players are frozen. Confer "last man standing" status to 
         -- the remaining player.
         --
         for each player do
            if current_team.last_man_standing == no_player and current_player.is_not_respawning() then 
               global.object[0] = current_player.biped
               if  global.object[0] != no_object
               and current_player.team == current_team
               and current_player.freeze_state != freeze_state_frozen
               then 
                  current_team.last_man_standing = current_player
                  current_player.is_last_man = 1
                  current_team.last_man_standing.biped.set_waypoint_visibility(enemies)
                  current_team.last_man_standing.biped.set_waypoint_priority(high)
                  current_team.last_man_standing.biped.set_waypoint_text("")
                  current_team.last_man_standing.biped.set_waypoint_icon(bullseye)
                  send_incident(inf_last_man, current_team.last_man_standing, all_players)
                  current_player.plasma_grenades = 1 -- grant last man standing a plasma grenade
               end
            end
         end
      end
   end
end
for each team do -- revoke last man standing status
   if current_team.has_any_players() then 
      global.number[2] = current_team.player_count
      global.number[2] -= 1
      if global.number[2] > current_team.frozen_player_count then 
         --
         -- A player has thawed; the last man standing is no longer the 
         -- last man standing.
         --
         global.player[0] = current_team.last_man_standing
         global.player[0].plasma_grenades = 0 -- revoke their plasma grenade
         global.player[0].is_last_man     = 0
         current_team.last_man_standing = no_player
      end
   end
end

for each team do -- victory condition: one team's players were all frozen or dead at the same time
   if  current_team.has_any_players()
   and current_team.last_man_standing != no_player
   and current_team.player_count == current_team.frozen_player_count
   then
      alias losing_team = global.team[2]
      --
      losing_team = current_team
      losing_team.last_man_standing = no_player
      game.show_message_to(global.team[2], none, "Your team was eliminated!")
      for each team do
         if current_team.has_any_players() and current_team != losing_team then 
            game.show_message_to(current_team, none, "You eliminated the enemy team!")
            current_team.score += game.score_to_win
         end
      end
   end
end

if game.round_time_limit > 0 and game.round_timer.is_zero() then -- victory/draw condition: time has run out (HAS BUGS)
   --
   -- The apparent purpose of this trigger is to award Score To Win many points to 
   -- the team with the fewest frozen players. However, either I'm decompiling it 
   -- incorrectly (unlikely) or 343i made a mistake when writing the code. It looks 
   -- like they screwed up when writing code to detect whether multiple teams have 
   -- the same number of frozen players -- a misplaced end-of-block marker somewhere 
   -- caused the "same number of frozen players" check to envelop the "lowest number 
   -- of frozen players" check.
   --
   -- The expected effect of this mistake is that in the event of the round time 
   -- elapsing, no team (literally no_team, actually) is awarded points.
   --
   alias MAX_PLAYERS          = 16
   alias winning_frozen_count = global.number[2]
   alias winning_team         = global.team[2]
   alias is_draw              = global.number[3] -- default-initialized to 0; never used anywhere else
   alias teams_present        = global.number[4] -- default-initialized to 0; never used anywhere else
   --
   winning_frozen_count = MAX_PLAYERS
   winning_team         = no_team
   for each team do
      teams_present += 1
      if current_team.has_any_players() and current_team.frozen_player_count == winning_frozen_count then
         --
         -- The above condition would only be met if a single team had 16 players on 
         -- it and every single one of them was frozen. It's also mutually exclusive 
         -- with the next condition.
         --
         is_draw = 1
         if current_team.has_any_players() and current_team.frozen_player_count < winning_frozen_count then 
            winning_frozen_count = current_team.frozen_player_count
            winning_team         = current_team
         end
      end
      --
      -- CORRECT CODE:
      --
      -- if current_team.has_any_players() and current_team.frozen_player_count == winning_frozen_count then
      --    --
      --    -- This condition would only be met if a single team had 16 players on 
      --    -- it and every single one of them was frozen... OR if we've already 
      --    -- found a team with a certain number of frozen players, and the team 
      --    -- we are now looking at has the same number of frozen players. Given 
      --    -- that Freeze Tag only allows two teams, that's enough to declare a 
      --    -- draw.
      --    --
      --    is_draw = 1
      -- end
      -- if current_team.has_any_players() and current_team.frozen_player_count < winning_frozen_count then 
      --    winning_frozen_count = current_team.frozen_player_count
      --    winning_team         = current_team
      --    --
      --    -- If you wanted to patch Freeze Tag to have more than two teams, then 
      --    -- you'd want to reset (is_draw) to 0 here.
      --    --
      -- end
      --
   end
   if is_draw == 0 then 
      winning_team.score += game.score_to_win
   end
   if is_draw == 1 or teams_present == 1 then 
      game.end_round()
   end
   --
   -- NOTE: Code further below tries to manage the round timer further, to make use 
   -- of Sudden Death and the grace period... but we've just ended the round here!
   --
end

for each team do -- manage object.current_carrier, object.away_state, flag waypoint, flag captures, etc.
   alias owned_flag   = global.object[0]
   alias flag_carrier = global.player[0]
   --
   owned_flag   = current_team.owned_flag
   flag_carrier = no_player
   global.number[5] = 0
   flag_carrier = owned_flag.try_get_carrier()
   if not flag_carrier == no_player then -- remember flag carrier for later, and confer traits and waypoint
      owned_flag.current_carrier = flag_carrier
      flag_carrier.apply_traits(carrier_traits)
      flag_carrier.biped.set_waypoint_visibility(everyone)
   end
   if flag_carrier == no_player and owned_flag.away_state != away_state_at_home then -- manage sudden death for dropped flags
      for each player do
         alias distance = global.number[2]
         --
         distance = 0
         global.object[1] = current_player.biped
         if current_player.team != owned_flag.team and global.object[1] != no_object then 
            distance = current_player.biped.get_distance_to(owned_flag)
            if distance < 15 then 
               in_sudden_death = 1 -- sudden death is enabled if someone is extremely close to a flag they can grab
            end
         end
      end
   end
   --
   -- We didn't need to check opt_ctf_enabled because the above conditions could 
   -- only ever be met if CTF was indeed enabled.
   --
   if opt_ctf_enabled == 1 and not flag_carrier == no_player then -- apply flag-carried state
      alias carrier_team = global.team[2]
      --
      owned_flag.set_waypoint_visibility(no_one)
      flag_carrier.biped.set_waypoint_icon(flag)
      flag_carrier.biped.set_waypoint_text("")
      owned_flag.away_state  = away_state_carried
      owned_flag.reset_timer = opt_flag_reset
      owned_flag.set_progress_bar(0, no_one)
      in_sudden_death = 1 -- sudden death is enabled if a flag is being carried
      --
      carrier_team = flag_carrier.team
      if carrier_team.flag_return_point.shape_contains(flag_carrier.biped) then -- handle flag captures
         --
         -- The flag has been brought to the capture point.
         --
         flag_carrier.score         += 1
         flag_carrier.flag_captures += 1
         current_team.owned_flag.delete()
         send_incident(flag_scored, flag_carrier, all_players)
      end
   end
   if flag_carrier == no_player and owned_flag.away_state == away_state_carried then -- apply flag-dropped state
      owned_flag.away_state = away_state_dropped
      owned_flag.set_waypoint_icon(flag)
      owned_flag.set_waypoint_visibility(everyone)
      current_team.owned_flag.set_waypoint_priority(high)
   end
end

for each team do -- handle flag resets
   alias owned_flag = global.object[0]
   --
   owned_flag = current_team.owned_flag
   if not owned_flag == no_object and owned_flag.away_state == away_state_dropped or owned_flag.away_state == 3 then 
      owned_flag.reset_timer.set_rate(-100%)
      for each object with label all_flags do -- blink a flag's waypoint when it's about to reset (REALLY weird that this loop is nested here)
         if current_object.reset_timer < 6 then
            current_object.set_waypoint_priority(blink)
         end
      end
      if owned_flag.is_out_of_bounds() or owned_flag.reset_timer.is_zero() then 
         owned_flag.delete()
         do -- why is this its own trigger lol
            --
            -- NOTE: Testing indicates that you cannot access data on a deleted object. 
            -- Their doing so here is a mistake.
            --
            send_incident(flag_reset_neutral, owned_flag.current_carrier, current_team)
         end
      end
   end
end

for each team do -- send incidents for the flag being taken or dropped
   alias current_flag    = global.object[0]
   alias current_carrier = global.player[0]
   --
   current_flag     = current_team.owned_flag
   global.object[1] = current_flag.current_carrier.biped
   current_carrier  = current_flag.current_carrier
   current_flag.notification_throttle.set_rate(-100%)
   if current_flag.notification_throttle.is_zero() then 
      if current_flag.away_state == away_state_dropped and current_flag.announced_flag_drop != 1 then 
         current_flag.announced_flag_drop = 1
         send_incident(flag_dropped_neutral, current_flag.current_carrier], current_team)
         current_flag.notification_throttle.reset()
      end
      if current_flag.away_state == away_state_carried and current_flag.announced_flag_take != 1 then 
         current_flag.announced_flag_take = 1
         send_incident(flag_grabbed_neutral, current_carrier, current_team)
         current_flag.notification_throttle.reset()
      end
      if current_flag.away_state != away_state_carried then 
         current_flag.announced_flag_take = 0
      end
      if current_flag.away_state == away_state_carried or current_flag.away_state == away_state_at_home then 
         current_flag.announced_flag_drop = 0
      end
   end
end

for each object with label all_flags do
   if current_object.object[0] == no_object then 
      current_object.object[0] = current_object.place_at_me(hill_marker, none, never_garbage_collect | suppress_effect, 0, 0, 0, none)
      current_object.object[0].set_shape(sphere, 10)
      current_object.object[0].set_shape_visibility(no_one)
      current_object.object[0].attach_to(current_object, 0, 0, 0, relative)
   end
end

for each object with label all_flags do -- clear object.current_carrier when the flag is dropped
   alias current_flag    = global.object[0]
   alias current_carrier = global.player[0]
   --
   current_flag = current_object
   if not current_flag.current_carrier == no_player then 
      for each player do
         if current_player == current_flag.player[0] then 
            current_carrier = no_player
            current_carrier = current_flag.try_get_carrier()
            if current_carrier == no_player then 
               current_flag.current_carrier = no_player
            end
         end
      end
   end
end

for each team do -- manage spawn zones for CTF
   if opt_ctf_enabled == 1 and current_team.has_any_players() then 
      alias current_flag = global.object[0]
      --
      current_flag = current_team.owned_flag
      if not current_flag == no_object then 
         for each object with label "ctf_res_zone" do
            if current_object.team == current_team then 
               current_object.enable_spawn_zone(0)
               current_object.set_shape_visibility(no_one)
               current_object.set_invincibility(1)
               current_object.set_pickup_permissions(no_one) -- in case the zone is a labeled weapon, i guess?
               if current_flag.away_state == away_state_at_home then 
                  current_object.enable_spawn_zone(1)
               end
            end
         end
         for each object with label "ctf_res_zone_away" do
            if current_object.team == current_team then 
               current_object.enable_spawn_zone(0)
               current_object.set_shape_visibility(no_one)
               current_object.set_invincibility(1)
               current_object.set_pickup_permissions(no_one) -- in case the zone is a labeled weapon, i guess?
               if not current_flag.away_state == away_state_at_home then 
                  current_object.enable_spawn_zone(1)
               end
            end
         end
      end
   end
end

for each team do -- delete a team's flag if all of the team's players quit and if the flag is at home
   if current_team != neutral_team and not current_team.has_any_players() and current_team.owned_flag != no_object then 
      global.object[0] = current_team.owned_flag
      if global.object[0].away_state == away_state_at_home then 
         current_team.owned_flag.delete()
         current_team.owned_flag = no_object
      end
   end
end

for each player do
   if current_player.is_not_respawning() then 
      alias is_carrier  = global.number[2]
      alias is_last_man = global.number[9]
      alias is_normal   = global.number[10]
      --
      is_carrier  = 0 -- 1 if this is the flag carrier
      is_last_man = 0 -- 1 if this is the last man standing
      is_normal   = 1 -- 0 if this is the flag carrier or the last man standing
      if current_player.freeze_state == freeze_state_frozen then 
         is_normal = 0
      end
      for each object with label all_flags do
         global.object[0] = current_object
         global.player[0] = no_player
         global.player[0] = global.object[0].try_get_carrier()
         if current_player == global.player[0] then 
            is_carrier = 1
            is_normal  = 0
         end
      end
      for each team do
         if current_player.team == current_team and current_player == current_team.last_man_standing then 
            is_last_man = 1
            is_normal   = 0
         end
      end
      if is_carrier == 0 and is_last_man == 1 then 
         current_player.biped.set_waypoint_icon(bullseye)
      end
      if is_normal == 1 then 
         current_player.biped.set_waypoint_visibility(allies)
         current_player.biped.set_waypoint_text("")
         current_player.biped.set_waypoint_icon(none)
         current_player.biped.set_waypoint_priority(normal)
      end
   end
end

-- More round timer management:
if not game.round_timer.is_zero() then 
   game.grace_period_timer = 0
end
if game.round_time_limit > 0 then
   --
   -- The intended design for the round timer is as follows:
   --
   --  - Round time
   --  - Sudden death time
   --  - Grace period time
   --
   -- Sudden death time is used whenever the conditions for sudden death are met (a player 
   -- is carrying a flag, or standing right on top of a flag they can pick up). The sudden 
   -- death timer never resets, but the grace period timer resets whenever sudden death is 
   -- active (such that it starts counting down from when sudden death conditions stop 
   -- being met).
   --
   -- The grace period time is only used when the conditions for sudden death are not met. 
   -- If the sudden death timer elapses while the conditions are met, then the grace 
   -- period time is not used.
   --
   if not game.round_timer.is_zero() then 
      announced_sudden_death = 0
   end
   if game.round_timer.is_zero() then
      --
      -- NOTE: The victory/draw condition code further up will have already detected this 
      -- condition and ended the round on its own. I wouldn't expect prolonging the round 
      -- here, via the grace period and sudden death timers, to work.
      --
      if in_sudden_death == 1 then 
         game.sudden_death_timer.set_rate(-100%)
         game.grace_period_timer.reset()
         if announced_sudden_death == 0 then 
            send_incident(sudden_death, all_players, all_players) -- announce sudden death
            announced_sudden_death = 1
         end
         if game.sudden_death_time > 0 and game.grace_period_timer > game.sudden_death_timer then 
            game.grace_period_timer = game.sudden_death_timer
         end
      end
      if in_sudden_death == 0 then 
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
