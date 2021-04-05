
enum sides
   multi
   one
   neutral
   three
end

alias opt_flag_return_time     = script_option[0]
alias opt_flag_return_points   = script_option[1]
alias opt_flag_reset_time      = script_option[2]
alias opt_sides                = script_option[3] -- see (sides) enum
alias opt_enemy_flag_points    = script_option[4]
alias opt_neutral_flag_points  = script_option[5]
alias opt_kill_points          = script_option[6]
alias opt_carrier_kill_bonus   = script_option[7]
alias opt_flag_at_home         = script_option[8]
alias opt_carrier_cooldown     = script_option[9]
alias opt_super_shields        = script_option[10]
alias opt_flag_return_radius   = script_option[11] -- range option; not visible in UI; defaults to 14
alias opt_flag_preserve_radius = script_option[12] -- range option; not visible in UI; defaults to 20

-- Unnamed Forge labels:
alias all_jetpacks    = 0
alias all_armor_locks = 1
alias all_flags       = 7
alias all_fire_vfx    = 8

alias carrier_traits  = script_traits[0]
alias cooldown_traits = script_traits[1]

alias ui_return_flag_to_score = script_widget[0]
alias ui_your_flag_is_away    = script_widget[1]
alias ui_your_flag_is_taken   = script_widget[2]

alias captures   = player.script_stat[0]
alias carry_time = player.script_stat[1]
alias returns    = player.script_stat[2]

enum flag_state
   at_home
   carried
   dropped
end

alias announced_game_start = player.number[2]
alias announce_start_timer = player.timer[3]

alias sudden_death_enabled   = global.number[0]
alias announced_sudden_death = global.number[1]
alias any_flag_is_being_preserved = global.number[3] -- is set, but nothing ever uses it
alias state    = object.number[0] -- flag state
alias announced_flag_take = object.number[2]
alias announced_flag_drop = object.number[3]
alias preserve_zone = object.object[0] -- boundary centered on the flag; enemies standing inside will prevent the flag from resetting
alias return_zone   = object.object[1] -- boundary centered on the flag
alias last_carrier  = object.player[0]
alias reset_timer   = object.timer[0]
alias return_timer  = object.timer[1] -- on flag.return_zone
alias lifespan      = object.timer[2] -- for Super Shields VFX
alias notification_throttle = object.timer[3]
alias ach_top_shot_count        = player.number[0]
alias ach_license_to_kill_count = player.number[1]
alias is_returning_flag         = player.number[3]
alias last_biped                = player.object[0]
alias ach_paper_beats_rock_vuln_timer = player.timer[0]
alias carrier_cooldown_timer          = player.timer[1]
alias carry_time_update_interval      = player.timer[2]
alias flag_point = team.object[0] -- spawn and drop point
alias flag       = team.object[1]

declare sudden_death_enabled   with network priority local
declare announced_sudden_death with network priority local
declare global.number[2] with network priority local
declare any_flag_is_being_preserved with network priority low
declare global.number[4] with network priority local
declare global.number[5] with network priority local
declare global.number[6] with network priority local
declare global.object[0] with network priority local
declare global.object[1] with network priority local
declare global.object[2] with network priority local
declare global.player[0] with network priority local
declare global.team[0] with network priority local
declare player.ach_top_shot_count        with network priority low
declare player.ach_license_to_kill_count with network priority low
declare player.announced_game_start      with network priority low
declare player.is_returning_flag with network priority low
declare player.last_biped with network priority low
declare player.carry_time_update_interval = 1
declare player.announce_start_timer = 5
declare object.state with network priority low
declare object.number[1] with network priority low = 1 -- unused
declare object.announced_flag_take with network priority local
declare object.announced_flag_drop with network priority local
declare object.preserve_zone with network priority low
declare object.return_zone   with network priority low
declare object.last_carrier  with network priority low
declare object.reset_timer  = opt_flag_reset_time
declare object.return_timer = opt_flag_return_time
declare object.lifespan     = 1
declare object.notification_throttle = 3
declare team.flag_point with network priority low
declare team.flag       with network priority low

do
   sudden_death_enabled = 0
end

for each player do -- award Dive Bomber achievement as appropriate
   alias killer    = global.player[0]
   alias killer_aa = global.object[0]
   alias death_mod = global.number[2]
   if current_player.killer_type_is(kill) then 
      killer    = no_player
      killer    = current_player.try_get_killer()
      death_mod = 0
      death_mod = current_player.try_get_death_damage_mod()
      if death_mod == enums.damage_reporting_modifier.assassination then 
         killer_aa = no_object
         killer_aa = killer.try_get_armor_ability()
         if killer_aa.has_forge_label(all_jetpacks) and killer_aa.is_in_use() then 
            send_incident(dlc_achieve_2, killer, killer, 65)
         end
      end
   end
end

for each player do -- award From Hell's Heart achievement as appropriate
   alias killer    = global.player[0]
   alias death_mod = global.number[2]
   if current_player.killer_type_is(kill) then 
      death_mod = 0
      death_mod = current_player.try_get_death_damage_mod()
      if death_mod == enums.damage_reporting_modifier.sticky then 
         killer = no_player
         killer = current_player.try_get_killer()
         if killer.killer_type_is(suicide) then 
            send_incident(dlc_achieve_2, current_player, current_player, 68)
         end
      end
   end
end

for each player do -- manage and award Top Shot achievement as appropriate
   alias killer    = global.player[0]
   alias death_mod = global.number[2]
   if current_player.killer_type_is(guardians | suicide | kill | betrayal | quit) then 
      current_player.ach_top_shot_count = 0
      if current_player.killer_type_is(kill) then 
         killer    = no_player
         killer    = current_player.try_get_killer()
         death_mod = 0
         death_mod = current_player.try_get_death_damage_mod()
         if death_mod != enums.damage_reporting_modifier.headshot then 
            killer.ach_top_shot_count = 0
         end
         if death_mod == enums.damage_reporting_modifier.headshot then 
            killer.ach_top_shot_count += 1
            if killer.ach_top_shot_count > 2 then 
               send_incident(dlc_achieve_2, killer, killer, 62)
            end
         end
      end
   end
end

for each player do -- manage and award License To Kill achievement as appropriate
   alias killer    = global.player[0]
   alias death_mod = global.number[2]
   alias vehicle   = global.object[0]
   if current_player.killer_type_is(kill) then 
      killer    = no_player
      killer    = current_player.try_get_killer()
      death_mod = 0
      death_mod = current_player.try_get_death_damage_mod()
      vehicle   = no_object
      vehicle   = killer.try_get_vehicle()
      if vehicle != no_object and death_mod == enums.damage_reporting_modifier.splatter then 
         killer.ach_license_to_kill_count += 1
         if killer.ach_license_to_kill_count > 4 then 
            send_incident(dlc_achieve_2, killer, killer, 66)
         end
      end
   end
end

for each player do -- manage timing for the Paper Beats Rock achievement
   alias current_ability = global.object[0]
   --
   current_ability = no_object
   current_ability = current_player.try_get_armor_ability()
   if current_ability.has_forge_label(all_armor_locks) and current_ability.is_in_use() then 
      current_player.ach_paper_beats_rock_vuln_timer = 4
      current_player.ach_paper_beats_rock_vuln_timer.set_rate(-100%)
   end
end
for each player do -- award Paper Beats Rock achievement as appropriate
   alias killer    = global.player[0]
   alias death_mod = global.number[2]
   if current_player.killer_type_is(kill) and not current_player.ach_paper_beats_rock_vuln_timer.is_zero() then 
      death_mod = 0
      death_mod = current_player.try_get_death_damage_mod()
      if death_mod == enums.damage_reporting_modifier.assassination then 
         killer = no_player
         killer = current_player.try_get_killer()
         send_incident(dlc_achieve_2, killer, killer, 60)
      end
   end
end

on pregame: do
   game.symmetry = 1
   if opt_sides == sides.one then 
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

for each player do -- round card
   current_player.announce_start_timer.set_rate(-100%)
   if opt_sides == sides.one and current_player.team == team[1] then 
      current_player.set_round_card_title("Capture the enemy flag.\r\n%n rounds.", game.round_limit)
      current_player.set_round_card_text("Offense")
      current_player.set_round_card_icon(attack)
   end
   if opt_sides == sides.one and current_player.team == team[0] then 
      current_player.set_round_card_title("Defend your flag.\r\n%n rounds.", game.round_limit)
      current_player.set_round_card_text("Defense")
      current_player.set_round_card_icon(defend)
   end
   if  game.score_to_win != 0
   and opt_sides == sides.neutral
   or  opt_sides == sides.multi
   or  opt_sides == sides.three
   then 
      current_player.set_round_card_title("Capture the flag.\r\n%n points to win.", game.score_to_win)
   end
   if  game.score_to_win == 0
   and opt_sides == sides.neutral
   or  opt_sides == sides.multi
   or  opt_sides == sides.three
   then 
      current_player.set_round_card_title("Capture the flag.")
   end
end
for each player do -- set up UI and announce game start
   ui_return_flag_to_score.set_text("Your flag must be at home to score!")
   ui_your_flag_is_away.set_text("Your flag is away")
   ui_your_flag_is_taken.set_text("The enemy has your flag!")
   ui_return_flag_to_score.set_visibility(current_player, false)
   ui_your_flag_is_away.set_visibility(current_player, false)
   ui_your_flag_is_taken.set_visibility(current_player, false)
   ui_your_flag_is_away.set_icon(flag)
   ui_your_flag_is_taken.set_icon(flag)
   --
   if current_player.announced_game_start == 0 and current_player.announce_start_timer.is_zero() then 
      send_incident(ctf_game_start, current_player, no_player)
      current_player.announced_game_start = 1
      if opt_sides == sides.one and current_player.team == team[1] then 
         send_incident(team_offense, current_player, no_player)
      end
      if opt_sides == sides.one and current_player.team == team[0] then 
         send_incident(team_defense, current_player, no_player)
      end
   end
end

for each team do -- initial setup for flag spawn/drop point
   if current_team.flag_point == no_object then 
      for each object with label "ctf_flag_return" do
         if current_team.flag_point == no_object and current_object.team == current_team then 
            current_team.flag_point = current_object
            current_object.set_waypoint_visibility(allies)
            current_object.set_waypoint_icon(destination)
         end
      end
   end
end

for each team do -- spawn flags as needed
   current_team.flag.set_waypoint_visibility(everyone)
   if  current_team == neutral_team
   or  current_team.has_any_players()
   and current_team.flag == no_object
   and not current_team.flag_point == no_object
   then
      alias should_spawn_flag = global.number[2]
      --
      should_spawn_flag = 0
      if opt_sides == sides.multi and not current_team == neutral_team and current_team.has_any_players() then 
         should_spawn_flag = 1
      end
      if opt_sides == sides.one and current_team == team[0] then
         team[1].flag_point.set_waypoint_visibility(everyone)
         team[0].flag_point.set_waypoint_visibility(no_one)
         should_spawn_flag = 1
      end
      if opt_sides == sides.neutral and current_team == neutral_team then 
         should_spawn_flag = 1
      end
      if opt_sides == sides.three then 
         should_spawn_flag = 1
      end
      if should_spawn_flag == 1 then 
         if opt_sides == sides.one or opt_sides == sides.neutral then
            --
            -- If this is One Flag or Neutral Flag, see if there is an existing flag 
            -- and if so, take ownership of it. (Perhaps this is meant to work around 
            -- some circumstance that can cause a flag to lose its ownership? But why 
            -- would that possibly occur?)
            --
            for each object do
               if current_object.is_of_type(flag) then 
                  current_team.flag = current_object
                  should_spawn_flag = 0
               end
            end
         end
         if opt_sides == sides.multi then
            --
            -- If this is Multi Flag and the flag somehow tests as unowned, take 
            -- ownership of it.
            --
            for each object do
               if current_object.is_of_type(flag) and should_spawn_flag == 1 then 
                  alias is_unowned = global.number[4]
                  --
                  is_unowned = 1
                  do -- check if flag carrier is on this team
                     global.player[0] = no_player
                     global.player[0] = current_object.try_get_carrier()
                     if not global.player[0] == no_player and global.player[0].team == current_team then 
                        is_unowned = 0 -- don't take ownership of an enemy flag being carried by one of our players
                     end
                  end
                  for each team do
                     if current_team.flag == current_object then 
                        is_unowned = 0
                     end
                  end
                  if is_unowned == 1 then 
                     current_team.flag = current_object
                     should_spawn_flag = 0
                  end
               end
            end
         end
         if should_spawn_flag == 1 then 
            current_team.flag = current_team.flag_point.place_at_me(flag, none, never_garbage_collect, 0, 0, 3, none)
         end
         --
         alias current_flag = global.object[0]
         --
         current_flag = current_team.flag
         if should_spawn_flag == 0 then 
            current_flag.state = flag_state.carried
         end
         current_flag.team = current_team
         current_team.flag.set_pickup_permissions(enemies)
         current_team.flag.set_weapon_pickup_priority(hold_action)
         current_team.flag.set_waypoint_icon(flag)
         current_team.flag.set_waypoint_priority(high)
         current_flag.set_shape(cylinder, 7, 6, 3)
         if current_team == neutral_team then 
            current_team.flag.set_pickup_permissions(everyone)
         end
      end
   end
end

for each player do -- clear scripted player waypoints
   current_player.biped.set_waypoint_icon(none)
end

for each team do -- manage object.current_carrier, object.away_state, flag waypoint, flag captures, etc.
   alias current_flag = global.object[0]
   alias flag_carrier = global.player[0]
   --
   current_flag = current_team.flag
   flag_carrier = no_player
   any_flag_is_being_preserved = 0
   flag_carrier = current_flag.try_get_carrier()
   if not flag_carrier == no_player then -- remember flag carrier for later, and confer traits and waypoint
      current_flag.last_carrier = flag_carrier
      flag_carrier.apply_traits(carrier_traits)
      --
      flag_carrier.carry_time_update_interval.set_rate(-100%)
      if flag_carrier.carry_time_update_interval.is_zero() then 
         flag_carrier.carry_time += 1
         flag_carrier.carry_time_update_interval.reset()
      end
   end
   if flag_carrier == no_player and current_flag.state != flag_state.at_home then -- manage sudden death for dropped flags
      for each player do
         alias distance = global.number[2]
         alias biped    = global.object[1]
         --
         distance = 0
         biped    = current_player.biped
         if current_player.team != current_flag.team and biped != no_object then 
            distance = current_player.biped.get_distance_to(current_flag)
            if distance < 15 then 
               sudden_death_enabled = 1 -- sudden death is enabled if someone is extremely close to a flag they can grab
            end
         end
      end
   end
   do
      alias return_zone = global.object[1] -- intermediate
      --
      return_zone = current_flag.return_zone
      if not flag_carrier == no_player then
         alias carrier_team = global.team[0]
         --
         current_flag.set_waypoint_visibility(no_one)
         flag_carrier.biped.set_waypoint_icon(flag)
         current_flag.state       = flag_state.carried
         current_flag.reset_timer = opt_flag_reset_time
         return_zone.return_timer = opt_flag_return_time
         current_flag.return_zone.set_progress_bar(object.reset_timer, no_one)
         sudden_death_enabled = 1
         flag_carrier.timer[1] = opt_carrier_cooldown
         carrier_team = flag_carrier.team
         if carrier_team.flag_point.shape_contains(flag_carrier.biped) then -- handle flag capture
            alias capture_is_allowed = global.number[2]
            alias carrier_team_flag  = global.object[2] -- intermediate
            --
            capture_is_allowed = 1
            ui_return_flag_to_score.set_visibility(flag_carrier, false)
            if opt_flag_at_home == 1 and opt_sides == sides.multi or opt_sides == sides.three then -- enforce Flag At Home
               carrier_team_flag = carrier_team.flag
               if not carrier_team_flag.state == flag_state.at_home then 
                  capture_is_allowed = 0
                  ui_return_flag_to_score.set_visibility(flag_carrier, true)
               end
            end
            if capture_is_allowed == 1 and current_flag.team == neutral_team then 
               flag_carrier.score += opt_neutral_flag_points
            end
            if capture_is_allowed == 1 and current_flag.team != neutral_team then 
               flag_carrier.score += opt_enemy_flag_points
            end
            if capture_is_allowed == 1 then 
               flag_carrier.captures += 1
               current_team.flag.delete()
               send_incident(flag_scored, flag_carrier, all_players)
            end
         end
      end
   end
   if flag_carrier == no_player and current_flag.state == flag_state.carried then 
      current_flag.state = flag_state.dropped
      if opt_flag_return_time != 1 then 
         current_flag.return_timer.set_progress_bar(object.return_timer, allies)
      end
      current_flag.set_waypoint_icon(flag)
      current_flag.set_waypoint_visibility(everyone)
      current_team.flag.set_waypoint_priority(high)
   end
end

for each player do -- award kill points
   alias killer = global.player[0]
   --
   global.number[2] = 0
   global.object[0] = current_player.biped
   if global.object[0] != no_object then 
      current_player.last_biped = global.object[0]
   end
   if current_player.killer_type_is(kill) then 
      killer = no_player
      killer = current_player.try_get_killer()
      killer.score += opt_kill_points
   end
end

for each team do -- handle flag returns and resets
   alias current_flag = global.object[0]
   alias return_zone  = global.object[1]
   --
   current_flag = current_team.flag
   return_zone  = current_flag.return_zone
   if not current_flag == no_object and current_flag.state == flag_state.dropped or current_flag.state == 3 then 
      current_flag.reset_timer.set_rate(-100%)
      return_zone.return_timer.set_rate(100%)
      --
      -- Identify players returning the flag:
      --
      for each player do
         current_player.is_returning_flag = 0
         if current_player.team == current_team and current_flag.return_zone.shape_contains(current_player.biped) then 
            current_player.is_returning_flag = 1
            return_zone.return_timer.set_rate(-100%)
            if opt_flag_return_time == 1 then 
               return_zone.return_timer.set_rate(-1000%)
            end
            current_flag.set_waypoint_priority(blink) -- blink the flag's waypoint if it's being returned
         end
      end
      --
      for each object with label all_flags do -- blink the flag's waypoint when it's about to reset
         if current_object.reset_timer < 6 then 
            current_object.set_waypoint_priority(blink)
         end
      end
      --
      -- Carry out resets and returns as appropriate:
      --
      if current_flag.is_out_of_bounds() or current_flag.reset_timer.is_zero() then -- carry out the reset
         current_flag.delete()
         if opt_sides == sides.neutral then 
            send_incident(flag_reset_neutral, current_flag.last_carrier, current_team)
         end
         if not opt_sides == sides.neutral and not opt_sides == sides.three then 
            send_incident(flag_reset, current_team, current_team)
         end
         if opt_sides == sides.three and current_team == neutral_team then 
            send_incident(flag_reset_neutral, current_flag.last_carrier, current_team)
         end
         if opt_sides == sides.three and current_team != neutral_team then 
            send_incident(flag_reset, current_team, current_team)
         end
      end
      if return_zone.return_timer.is_zero() then -- carry out the return
         current_flag.delete()
         send_incident(flag_recovered, current_team, current_team)
         for each player do -- credit players for returning flags
            if current_player.is_returning_flag == 1 and current_player.team == current_team then 
               current_player.returns += 1
               current_player.score   += opt_flag_return_points
               current_player.is_returning_flag = 0
               if current_player.returns > 1 then -- award "Return to Sender" achievement as appropriate
                  send_incident(dlc_achieve_1, current_player, current_player)
               end
            end
         end
      end
   end
end

for each team do -- send incidents for the flag being taken or dropped
   alias current_flag    = global.object[0]
   alias current_carrier = global.player[0]
   alias carrier_biped   = global.object[1]
   --
   current_flag    = current_team.flag
   carrier_biped   = current_flag.last_carrier.biped
   current_carrier = current_flag.last_carrier
   current_flag.notification_throttle.set_rate(-100%)
   if current_flag.notification_throttle.is_zero() then 
      if current_flag.state == flag_state.dropped and current_flag.announced_flag_drop != 1 then 
         current_flag.announced_flag_drop = 1
         if opt_sides == sides.neutral then 
            send_incident(flag_dropped_neutral, current_flag.last_carrier, current_team)
         end
         if not opt_sides == sides.neutral and not opt_sides == sides.three then 
            send_incident(flag_dropped, current_flag.last_carrier, current_team)
         end
         if opt_sides == sides.three and current_team == neutral_team then 
            send_incident(flag_dropped_neutral, current_flag.last_carrier, current_team)
         end
         if opt_sides == sides.three and current_team != neutral_team then 
            send_incident(flag_dropped, current_flag.last_carrier, current_team)
         end
         current_flag.notification_throttle.reset()
      end
      if current_flag.state == flag_state.carried and current_flag.announced_flag_take != 1 then 
         current_flag.announced_flag_take = 1
         if opt_sides == sides.neutral then 
            send_incident(flag_grabbed_neutral, current_carrier, current_team)
         end
         if not opt_sides == sides.neutral and not opt_sides == sides.three then 
            send_incident(flag_grabbed, current_carrier, current_team)
         end
         if opt_sides == sides.three and current_team == neutral_team then 
            send_incident(flag_grabbed_neutral, current_carrier, current_team)
         end
         if opt_sides == sides.three and current_team != neutral_team then 
            send_incident(flag_grabbed, current_carrier, current_team)
         end
         current_flag.notification_throttle.reset()
      end
      if current_flag.state != flag_state.carried then 
         current_flag.announced_flag_take = 0
      end
      if current_flag.state == flag_state.carried or current_flag.state == flag_state.at_home then 
         current_flag.announced_flag_drop = 0
      end
   end
end

for each player do -- carrier cooldown traits
   alias current_biped  = global.object[0]
   alias current_weapon = global.object[1]
   --
   current_biped = current_player.biped
   if not current_biped == no_object then 
      current_weapon = no_object
      current_weapon = current_player.try_get_weapon(primary)
      if not current_weapon.is_of_type(flag) and current_player.last_carrier_cooldown_timer > 0 then 
         current_player.last_carrier_cooldown_timer.set_rate(-100%)
         if not current_player.last_carrier_cooldown_timer.is_zero() then 
            current_player.apply_traits(cooldown_traits)
         end
      end
   end
end

for each team do -- handle the carrier being killed
   alias current_flag = global.object[0]
   alias killer       = global.player[0]
   alias death_mod    = global.number[2]
   if current_team.has_any_players() then 
      current_flag = current_team.flag
      for each player do
         if current_flag.last_carrier.killer_type_is(kill) then 
            killer = no_player
            killer = current_flag.last_carrier.try_get_killer()
            send_incident(flagcarrier_kill, killer, current_flag.last_carrier)
            killer.score += opt_carrier_kill_bonus
            --
            -- Award "Stick It To The Man!" achievement as appropriate:
            --
            death_mod = 0
            death_mod = current_flag.last_carrier.try_get_death_damage_mod()
            if death_mod == enums.damage_reporting_modifier.sticky then 
               killer = current_flag.last_carrier.try_get_killer()
               send_incident(dlc_achieve_2, killer, killer, 64)
            end
            --
            current_flag.last_carrier = no_player
         end
      end
   end
end

for each object with label all_flags do -- create a preserve boundary for each flag
   if current_object.preserve_zone == no_object then 
      current_object.preserve_zone = current_object.place_at_me(hill_marker, none, never_garbage_collect | suppress_effect, 0, 0, 0, none)
      current_object.preserve_zone.set_shape(cylinder, opt_flag_preserve_radius, 10, 10) -- option defaults to 20
      current_object.preserve_zone.set_shape_visibility(no_one)
      current_object.preserve_zone.attach_to(current_object, 0, 0, 0, relative)
   end
end
for each object with label all_flags do -- create a return boundary for each flag
   if current_object.return_zone == no_object then 
      current_object.return_zone = current_object.place_at_me(hill_marker, none, never_garbage_collect | suppress_effect, 0, 0, 0, none)
      global.object[0] = current_object.return_zone
      global.object[0].team = current_object.team
      current_object.return_zone.set_shape(cylinder, opt_flag_return_radius, 10, 10) -- option defaults to 14
      current_object.return_zone.set_shape_visibility(no_one)
      current_object.return_zone.attach_to(current_object, 0, 0, 0, relative)
   end
end

for each object with label all_flags do -- handle preserve boundaries
   alias current_flag = global.object[0]
   if opt_sides == sides.one then 
      current_flag = current_object
      for each player do
         if  not current_player.team == current_flag.team
         and current_flag.preserve_zone.shape_contains(current_player.biped)
         then 
            any_flag_is_being_preserved = 1
            current_flag.reset_timer.set_rate(0%)
         end
      end
   end
end

for each object with label all_flags do -- detect a flag being dropped
   alias current_flag    = global.object[0]
   alias current_carrier = global.player[0]
   --
   current_flag = current_object
   if not current_flag.last_carrier == no_player then 
      for each player do -- can't think of any reason to loop here other than to avoid running this if the carrier quits?
         if current_player == current_flag.last_carrier then 
            current_carrier = no_player
            current_carrier = current_flag.try_get_carrier()
            if current_carrier == no_player then 
               current_flag.last_carrier = no_player
            end
         end
      end
   end
end

for each team do -- manage CTF spawn zones
   if current_team.has_any_players() then 
      global.object[0] = current_team.flag
      if not global.object[0] == no_object then 
         for each object with label "ctf_res_zone" do
            if current_object.team == current_team then 
               current_object.enable_spawn_zone(0)
               current_object.set_shape_visibility(no_one)
               current_object.set_invincibility(1)
               current_object.set_pickup_permissions(no_one)
               if global.object[0].state == flag_state.at_home then 
                  current_object.enable_spawn_zone(1)
               end
            end
         end
         for each object with label "ctf_res_zone_away" do
            if current_object.team == current_team then 
               current_object.enable_spawn_zone(0)
               current_object.set_shape_visibility(no_one)
               current_object.set_invincibility(1)
               current_object.set_pickup_permissions(no_one)
               if not global.object[0].state == flag_state.at_home then 
                  current_object.enable_spawn_zone(1)
               end
            end
         end
      end
   end
end

for each team do -- delete a team's flag if all of their players quit and their flag is at home
   alias current_flag = global.object[0]
   if current_team != neutral_team and not current_team.has_any_players() and current_team.flag != no_object then 
      current_flag = current_team.flag
      if current_flag.state == flag_state.at_home then 
         current_team.flag.delete()
         current_team.flag = no_object
      end
   end
end

for each player do -- manage flag state UI visibility
   alias current_biped = global.object[0]
   alias current_flag  = global.object[1]
   --
   current_biped  = current_player.biped
   global.team[0] = current_player.team -- intermediate
   current_flag   = global.team[0].flag
   if current_biped != no_object then -- hide these widgets when the player is waiting to respawn
      if current_flag.state == flag_state.carried then 
         ui_your_flag_is_taken.set_visibility(current_player, true)
      end
      if current_flag.state == flag_state.dropped then 
         ui_your_flag_is_away.set_visibility(current_player, true)
      end
   end
end

-- Super Shields
for each player do -- spawn fire emitters
   alias current_shields = global.number[2]
   alias vfx_probability = global.number[4]
   if opt_super_shields == 1 then 
      current_shields = 0
      current_shields = current_player.biped.shields
      if current_shields > 100 then 
         vfx_probability = 0
         vfx_probability = rand(10)
         if vfx_probability <= 2 then -- 30% chance
            current_player.biped.place_at_me(particle_emitter_fire, none, never_garbage_collect, 0, 0, 0, none)
         end
      end
   end
end
for each object with label all_fire_vfx do -- delete fire emitters
   current_object.lifespan.set_rate(-100%)
   if current_object.lifespan.is_zero() then 
      current_object.delete()
   end
end

for each team do -- award "Don't Touch That" achievement as appropriate
   alias penultimate_round_number  = global.number[2]
   alias total_defender_carry_time = global.number[4]
   alias total_attacker_carry_time = global.number[5]
   alias teams_are_alternating     = global.number[6]
   if opt_sides == sides.one and current_team.has_any_players() then 
      global.object[0] = current_team.flag
      penultimate_round_number = 0
      penultimate_round_number = game.round_limit
      penultimate_round_number -= 1
      if game.current_round == penultimate_round_number and game.round_time_limit > 0 and game.round_timer.is_zero() then 
         total_defender_carry_time = 0
         for each player do
            if current_player.team == team[0] then 
               total_defender_carry_time += current_player.carry_time
            end
         end
         total_attacker_carry_time = 0
         for each player do
            if current_player.team == team[1] then 
               total_attacker_carry_time += current_player.carry_time
            end
         end
         --
         teams_are_alternating = game.current_round
         teams_are_alternating %= 2
         for each player do
            if current_player.team == team[0] and total_attacker_carry_time == 0 then 
               send_incident(dlc_achieve_2, current_player, current_player, 59)
            end
         end
         for each player do
            if teams_are_alternating == 1 and current_player.team == team[1] and total_defender_carry_time == 0 then 
               send_incident(dlc_achieve_2, current_player, current_player, 59)
            end
         end
      end
   end
end

-- Manage round timer:
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
