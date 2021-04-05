
alias opt_collect_time   = script_option[0]
alias opt_flag_count     = script_option[1]
alias opt_flag_placement = script_option[2]
alias opt_synchronize    = script_option[3]
alias opt_lock_flags     = script_option[4]
alias opt_carry_cooldown = script_option[5]

-- Unnamed Forge labels:
alias all_flags         = 4
alias all_respawn_zones = 5

alias carrier_traits  = script_traits[0]
alias cooldown_traits = script_traits[1]

alias carry_time = player.script_stat[0]

alias announced_game_start = player.number[0]
alias announce_start_timer = player.timer[2]

alias flags_on_map                = global.number[0]
alias flags_collected_this_frame  = global.number[1] -- local variable; only used for incidents and achievements
alias did_desynchronize           = global.number[2]
alias base_collection_timer       = global.timer[0] -- used only for desynchronizing stockpiles at the start, it seems
alias flag_spawn_timeout          = global.timer[1] -- this is a short timeout but bear in mind, when this is running we're trying to spawn a flag every frame
alias has_flag                    = object.number[0] -- does a spawn zone contain a flag?
alias is_in_unfair_to_others_zone = object.number[1]
alias average_distance_to_winners = object.number[2] -- used for Fair spawning; average distance from a flag spawn to all 1st-place teams' stockpiles
alias last_carrier                = object.player[0] -- person currently carrying this flag, or the last person to carry it
alias deposited_by                = object.player[1] -- who put this flag in their team's stockpile?
alias collection_timer            = object.timer[0]
alias reset_timer                 = object.timer[1]
alias carrier_cooldown_timer      = player.timer[0]
alias carry_time_interval         = player.timer[1]
alias flags_collected_this_frame  = team.number[0]
alias active_goal                 = team.object[0]
alias scripted_spawn_zone         = team.object[1]
alias unfair_to_others_zone       = team.object[2]

declare flags_on_map with network priority local
declare flags_collected_this_frame with network priority local
declare did_desynchronize with network priority low
declare global.number[3] with network priority local
declare global.number[4] with network priority local
declare global.number[5] with network priority local
declare global.number[6] with network priority local
declare global.object[0] with network priority local
declare global.object[1] with network priority local
declare global.object[2] with network priority local
declare global.player[0] with network priority local
declare global.player[1] with network priority local
declare global.team[0] with network priority local
declare base_collection_timer = opt_collect_time
declare flag_spawn_timeout = 1
declare player.announced_game_start with network priority low
declare player.carry_time_interval  = 1 -- increase the "Carry Time" stat by one every one second
declare player.announce_start_timer = 5
declare object.has_flag with network priority low
declare object.is_in_unfair_to_others_zone with network priority low
declare object.average_distance_to_winners with network priority low
declare object.last_carrier with network priority low
declare object.deposited_by with network priority low
declare object.collection_timer = opt_collect_time
declare object.reset_timer      = 62
declare team.flags_collected_this_frame with network priority low
declare team.active_goal           with network priority low
declare team.scripted_spawn_zone   with network priority local
declare team.unfair_to_others_zone with network priority local

on init: do
   base_collection_timer -= 1
end

for each player do -- loadout palettes
   if current_player.is_elite() then 
      current_player.set_loadout_palette(elite_tier_1)
   end
   if not current_player.is_elite() then 
      current_player.set_loadout_palette(spartan_tier_1)
   end
end

for each player do -- round card and announce game start timer
   current_player.announce_start_timer.set_rate(-100%)
   if game.score_to_win != 0 then 
      current_player.set_round_card_title("Collect flags for your team.\r\n%n points to win.", game.score_to_win)
   end
   if game.score_to_win == 0 then 
      current_player.set_round_card_title("Collect flags for your team.")
   end
end
for each player do -- announce game start
   if current_player.announced_game_start == 0 and current_player.announce_start_timer.is_zero() then 
      send_incident(stockpile_game_start, current_player, no_player)
      current_player.announced_game_start = 1
   end
end

if opt_synchronize == 0 and did_desynchronize == 0 then -- desynchronize stockpile timers as appropriate
   alias goals_minus_one = global.number[3]
   alias half_timer      = global.number[4]
   --
   goals_minus_one = -1
   half_timer = opt_collect_time
   half_timer /= 2
   for each object with label "stp_goal" do
      current_object.collection_timer = base_collection_timer
      goals_minus_one += 1
      if goals_minus_one == 0 or goals_minus_one == 2 or goals_minus_one == 4 then 
         current_object.collection_timer -= half_timer
      end
   end
   did_desynchronize = 1
end

do -- initial setup for goals and spawning
   base_collection_timer.set_rate(-100%)
   for each object with label "stp_goal" do
      global.team[0] = current_object.team
      if global.team[0].has_any_players() and global.team[0].active_goal == no_object then 
         global.team[0].active_goal = current_object
         current_object.set_waypoint_visibility(allies)
         current_object.set_waypoint_icon(defend)
         current_object.set_waypoint_timer(0)
         current_object.set_shape_visibility(everyone)
      end
   end
   for each object with label "stp_flag" do
      current_object.set_shape(cylinder, 25, 5, 5)
      current_object.set_waypoint_visibility(no_one)
   end
   for each team do
      alias working = global.object[0]
      if current_team.has_any_players() and current_team.scripted_spawn_zone == no_object then 
         current_team.scripted_spawn_zone = current_team.active_goal.place_at_me(respawn_zone, none, never_garbage_collect, 0, 0, 0, none)
         working = current_team.scripted_spawn_zone
         working.set_shape(cylinder, 150, 50, 50)
         working.team = current_team
         working.set_invincibility(1)
         working.set_pickup_permissions(no_one)
         working.set_shape_visibility(no_one)
         if opt_flag_placement == 1 then 
            current_team.unfair_to_others_zone = working
         end
      end
   end
   for each object with label "stp_goal" do
      current_object.collection_timer.set_rate(-100%)
   end
end

on host migration: do -- delete respawn zones on host migration
   for each object with label all_respawn_zones do
      current_object.delete()
   end
end

if flags_on_map < opt_flag_count then -- track the number of flags on the map
   flags_on_map = 0
   for each object with label all_flags do
      flags_on_map += 1
   end
end

for each object with label "stp_flag" do -- track the fairness of each flag spawn
   alias teams_in_lead      = global.number[4]
   alias distance_to_winner = global.number[6] -- distance between a flag spawn and the winner's stockpile
   alias average_to_winners = global.number[3] -- average distance between a flag and all winning teams' stockpiles
   --
   current_object.is_in_unfair_to_others_zone = 0
   current_object.has_flag = 0
   current_object.average_distance_to_winners = 0
   average_to_winners = 0
   teams_in_lead      = 0
   if opt_flag_placement == 1 then -- Fair placement
      for each team do
         if current_team.has_any_players() then 
            global.number[5] = 0
            global.number[5] = current_team.get_scoreboard_pos()
            if global.number[5] == 1 then -- current_team is in the lead
               teams_in_lead += 1
               distance_to_winner = 0
               distance_to_winner = current_team.active_goal.get_distance_to(current_object)
               average_to_winners += distance_to_winner
               if current_team.unfair_to_others_zone.shape_contains(current_object) then -- this is just the team's scripted respawn zone
                  current_object.is_in_unfair_to_others_zone = 1
               end
            end
         end
      end
      average_to_winners /= teams_in_lead
      current_object.average_distance_to_winners = average_to_winners
   end
end

for each player do -- clear scripted waypoints from player bipeds
   current_player.biped.set_waypoint_icon(none)
end

for each object with label all_flags do -- manage flag collection and resets
   alias current_flag = global.object[0]
   alias current_goal = global.object[1]
   --
   current_flag = current_object
   current_flag.team = neutral_team
   current_flag.set_waypoint_priority(normal)
   current_flag.reset_timer.set_rate(-100%)
   for each team do
      if current_team.has_any_players() and current_team.active_goal.shape_contains(current_flag) then 
         alias last_carrier = global.player[0]
         --
         current_flag.team = current_team
         current_goal = current_team.active_goal
         last_carrier = current_flag.last_carrier
         if current_flag.team == last_carrier.team and current_flag.deposited_by == no_player then 
            current_flag.deposited_by = current_flag.last_carrier
         end
         if current_flag.team == last_carrier.team and not current_flag.deposited_by == no_player then 
            global.player[1] = current_flag.deposited_by
            if global.player[1].team != last_carrier.team then 
               current_flag.deposited_by = current_flag.last_carrier
            end
         end
         current_flag.reset_timer.reset()
         if current_goal.collection_timer.is_zero() then -- scoring
            if not current_flag.team == last_carrier.team then 
               --
               -- The flag was dropped in this goal by an enemy, or it ended up in 
               -- this goal by happenstance. Don't award a point to any specific 
               -- player.
               --
               current_team.score += 1
            end
            if current_flag.team == last_carrier.team then
               --
               -- The flag was dropped in this goal by a player on this team. Award 
               -- them with a point.
               --
               current_flag.deposited_by.score += 1
            end
            flags_collected_this_frame = 1
            current_team.flags_collected_this_frame += 1
            current_flag.delete()
            flags_on_map -= 1
         end
      end
   end
   if not current_flag == no_object then 
      for each object with label "stp_flag" do
         if current_object.shape_contains(current_flag) then 
            current_object.has_flag = 1
            current_flag.reset_timer.reset()
         end
      end
      do
         alias current_carrier = global.player[0]
         --
         current_flag.set_waypoint_visibility(everyone)
         current_carrier = no_player
         current_carrier = current_flag.try_get_carrier()
         if not current_carrier == no_player then 
            current_flag.set_waypoint_visibility(no_one)
            current_flag.reset_timer.reset() -- prolong a flag's lifespan if it's being carried
            current_flag.last_carrier = current_carrier
            current_carrier.biped.set_waypoint_icon(flag)
            current_carrier.apply_traits(carrier_traits)
            do
               alias current_weapon = global.object[1]
               --
               current_weapon = no_object
               current_weapon = current_carrier.try_get_weapon(primary)
               if current_weapon.is_of_type(flag) then 
                  current_carrier.carrier_cooldown_timer = opt_carry_cooldown
               end
            end
            --
            -- Manage "carry time" stat:
            --
            current_carrier.carry_time_interval.set_rate(-100%)
            if current_carrier.carry_time_interval.is_zero() then 
               current_carrier.carry_time += 1
               current_carrier.carry_time_interval.reset()
            end
         end
      end
      if current_object.is_out_of_bounds() or current_object.reset_timer.is_zero() then 
         current_object.delete()
         flags_on_map -= 1
         send_incident(stock_flag_reset, all_players, all_players)
      end
   end
end

for each object with label "stp_goal" do -- loop the collection timer
   current_object.collection_timer.set_rate(-100%)
   if current_object.collection_timer.is_zero() then 
      current_object.collection_timer.reset()
   end
end

for each object with label "stp_goal" do -- blink goal and flag waypoints when appropriate
   alias current_goal = global.object[0]
   alias current_flag = global.object[1]
   --
   current_goal = current_object
   current_goal.set_waypoint_priority(high)
   if current_object.collection_timer < 6 then -- blink goal and flag waypoints when collection will occur soon
      current_goal.set_waypoint_priority(blink)
      for each object with label all_flags do
         current_flag = current_object
         if current_goal.shape_contains(current_flag) then 
            current_flag.set_waypoint_priority(blink)
         end
      end
   end
end

do -- spawn flags
   flags_on_map = 0
   flag_spawn_timeout.set_rate(100%)
   for each object with label all_flags do
      flags_on_map += 1
   end
   if flags_on_map < opt_flag_count then 
      alias spawn_allowed  = global.number[3]
      alias selected_spawn = global.object[0]
      alias fallback_spawn = global.object[1] -- use if we are unable to find an ideal spawn for a full second
      alias created_flag   = global.object[2]
      --
      spawn_allowed  = 1
      selected_spawn = no_object
      selected_spawn = get_random_object("stp_flag", no_object)
      if  opt_flag_placement == 1
      and selected_spawn.is_in_unfair_to_others_zone == 1 -- spawn point is in a winning team's scripted respawn zone
      or  flag_spawn_timeout.is_zero()
      then 
         spawn_allowed = 0
         flag_spawn_timeout.set_rate(-100%)
      end
      for each object with label "stp_goal" do -- avoid spawn points that are inside of goal points
         global.object[1] = current_object
         if global.object[1].shape_contains(selected_spawn) then 
            spawn_allowed = 0
         end
      end
      if selected_spawn.has_flag == 1 then -- avoid spawn points that already contain a flag
         spawn_allowed = 0
      end
      if spawn_allowed == 1 or flag_spawn_timeout.is_zero() then 
         fallback_spawn = no_object
         for each object with label "stp_flag" do
            if  fallback_spawn.average_distance_to_winners < current_object.average_distance_to_winners
            or  fallback_spawn == no_object
            and current_object.has_flag == 0
            then 
               fallback_spawn = current_object
            end
         end
         created_flag = no_object
         if flag_spawn_timeout.is_zero() then 
            selected_spawn = fallback_spawn
         end
         created_flag = selected_spawn.place_at_me(flag, none, never_garbage_collect, 0, 0, 3, none)
         created_flag.team = neutral_team
         if selected_spawn.is_of_type(flag_stand) then 
            created_flag.attach_to(selected_spawn, 0, 0, 3, absolute)
         end
      end
   end
end

if game.round_time_limit > 0 and game.round_timer.is_zero() then -- round timer
   game.end_round()
end

for each object with label all_flags do -- manage flag pickup permissions and waypoints
   current_object.set_waypoint_icon(flag)
   current_object.set_pickup_permissions(everyone)
   current_object.set_weapon_pickup_priority(hold_action)
   if current_object.reset_timer < 6 then 
      current_object.set_waypoint_priority(blink)
   end
   if opt_lock_flags == 1 and not current_object.team == neutral_team then 
      current_object.set_pickup_permissions(enemies)
   end
end

for each player do -- apply cooldown traits
   alias current_biped  = global.object[0]
   alias current_weapon = global.object[1]
   --
   current_biped = current_player.biped
   if not current_biped == no_object then 
      current_weapon = no_object
      current_weapon = current_player.try_get_weapon(primary)
      if not current_weapon.is_of_type(flag) and current_player.carrier_cooldown_timer > 0 then 
         current_player.carrier_cooldown_timer.set_rate(-100%)
         if not current_player.carrier_cooldown_timer.is_zero() then 
            current_player.apply_traits(cooldown_traits)
         end
      end
   end
end

if flags_collected_this_frame == 1 then -- "Flags collected" incident and "You Ate All The Chips" achievement
   for each team do -- award "You Ate All The Chips" achievement when appropriate
      alias flags_scored = global.number[3]
      --
      flags_scored = current_team.flags_collected_this_frame
      if flags_scored > 0 then 
         current_team.flags_collected_this_frame = 0
         if flags_scored == opt_flag_count then 
            for each player do
               if current_player.team == current_team then 
                  send_incident(dlc_achieve_6, current_player, no_player)
               end
            end
         end
      end
   end
   send_incident(stock_flags_collected, all_players, all_players)
   flags_collected_this_frame = 0
end
