
alias carrier_traits = script_traits[0]

alias announced_game_start = player.number[0]
alias announce_start_timer = player.timer[2]

alias flags_collected_this_frame = global.number[0] -- bool; unused leftover from Stockpile; code is incomplete so it ends up being "have any flags ever been scored?"
alias flags_on_map       = global.number[1]
alias flag_spawns_on_map = global.number[2]
alias flag_spawn_timeout = global.timer[0]
alias has_flag     = object.number[0] -- does this spawn point contain a flag?
alias points       = object.number[2]
alias average_distance_to_winners = object.number[3] -- Stockpile leftover for fair spawning
alias is_carried   = object.number[4]
alias spawned_from = object.object[0]
alias carrier      = object.player[2]
alias reset_timer  = object.timer[0]
alias carried_flag_count = player.number[1]

-- Unnamed Forge labels
alias all_flags = 4

declare flags_collected_this_frame with network priority local
declare flags_on_map       with network priority low
declare flag_spawns_on_map with network priority low
declare global.number[3] with network priority low
declare global.number[4] with network priority local
declare global.number[5] with network priority local
declare global.object[0] with network priority local
declare global.object[1] with network priority local
declare global.object[2] with network priority local
declare global.object[3] with network priority local
declare global.player[0] with network priority local
declare global.team[0] with network priority local
declare flag_spawn_timeout = 1 -- this is a short timeout but bear in mind, when this is running we're trying to spawn a flag every frame
declare player.announced_game_start with network priority low
declare player.carried_flag_count   with network priority low
declare player.timer[1] = 1
declare player.announce_start_timer = 5
declare object.has_flag with network priority low
declare object.number[1] with network priority low
declare object.points with network priority low = 1
declare object.average_distance_to_winners with network priority low
declare object.is_carried   with network priority low
declare object.spawned_from with network priority low
declare object.player[0] with network priority low
declare object.player[1] with network priority low
declare object.carrier with network priority low
declare object.reset_timer = 62
declare team.number[0] with network priority low   -- unused
declare team.object[0] with network priority low   -- unused
declare team.object[1] with network priority local -- unused
declare team.object[2] with network priority local -- unused

for each player do -- loadout palettes
   if current_player.is_elite() then 
      current_player.set_loadout_palette(elite_tier_1)
   end
   if not current_player.is_elite() then 
      current_player.set_loadout_palette(spartan_tier_1)
   end
end

for each player do -- round card, HUD setup, and announce game start
   current_player.announce_start_timer.set_rate(-100%)
   current_player.biped.set_waypoint_icon(none)
   script_widget[0].set_text("Carrying %n flags", hud_player.carried_flag_count)
   script_widget[0].set_icon(flag)
   if game.score_to_win != 0 then 
      current_player.set_round_card_title("Score %n points by collecting flags \nand returning them to your base!", game.score_to_win)
   end
   if game.score_to_win == 0 then 
      current_player.set_round_card_title("Score points by collecting flags and returning them to your base!")
   end
   if current_player.announced_game_start == 0 and current_player.announce_start_timer.is_zero() then 
      send_incident(action_sack_game_start, current_player, no_player)
      current_player.announced_game_start = 1
   end
end

for each object with label "speedpile_goal" do -- manage goal visibility
   global.number[4] = current_object.spawn_sequence -- unused
   current_object.set_waypoint_visibility(allies)
   current_object.set_waypoint_icon(destination)
   current_object.set_waypoint_priority(high)
   current_object.set_shape_visibility(everyone)
end

for each object with label "flag_spawn_loc" do
   current_object.number[1] = 0 -- unused
   current_object.has_flag  = 0
   current_object.average_distance_to_winners = 0
   global.number[4] = 0 -- this is a temporary, so not sure why it's zeroed out here
   global.number[5] = 0 -- this is a temporary, so not sure why it's zeroed out here
end

do -- count flags and flag spawn points on the map
   flag_spawns_on_map = 0
   for each object with label "flag_spawn_loc" do
      flag_spawns_on_map += 1
   end
   flags_on_map = 0
   for each object with label 4 do
      flags_on_map += 1
   end
end

for each object with label all_flags do
   alias current_flag = global.object[0]
   --
   current_flag = current_object
   global.team[0] = current_object.team
   current_flag.reset_timer.set_rate(-100%)
   current_object.set_waypoint_icon(territory_a, current_object.points)
   current_object.set_waypoint_visibility(everyone)
   for each object with label "speedpile_goal" do
      if current_flag.is_carried == 1 and current_object.shape_contains(current_flag) then 
         current_flag.reset_timer.reset()
         global.player[0] = no_player
         for each player do
            if global.object[0].carrier == current_player then 
               global.player[0] = current_player
            end
         end
         if global.player[0].team == current_object.team then 
            global.player[0].carried_flag_count -= 1
            global.player[0].score += current_flag.points
            flags_collected_this_frame = 1
            current_flag.detach()
            current_flag.delete()
            current_flag.is_carried = 0 -- Modifying after deleting? I don't think that should work...
            flags_on_map -= 1
         end
      end
   end
   if not current_flag == no_object then 
      for each object with label "flag_spawn_loc" do
         if current_object.shape_contains(current_flag) then 
            current_object.has_flag = 1
            current_flag.reset_timer.reset()
         end
      end
      if current_flag.is_carried != 0 then 
         current_flag.reset_timer.reset()
      end
      if current_object.is_out_of_bounds() or current_object.reset_timer.is_zero() then 
         flags_on_map -= 1
         if current_object.carrier != no_player then 
            global.player[0] = current_object.carrier
            global.player[0].carried_flag_count -= 1
         end
         current_object.delete()
      end
   end
end

do -- spawn flags
   flag_spawn_timeout.set_rate(100%)
   if flags_on_map < flag_spawns_on_map then
      alias selected_spawn = global.object[0]
      alias fallback_spawn = global.object[1]
      alias spawn_allowed  = global.number[4]
      alias created_flag   = global.object[2]
      alias created_vfx    = global.object[3]
      --
      spawn_allowed = 1
      selected_spawn = no_object
      selected_spawn = get_random_object("flag_spawn_loc", no_object)
      for each object with label "speedpile_goal" do -- reject spawn points that are inside of goals
         alias current_goal = global.object[1]
         current_goal = current_object
         if current_goal.shape_contains(selected_spawn) then 
            spawn_allowed = 0
         end
      end
      if selected_spawn.has_flag == 1 then -- reject spawn points that contain a flag
         spawn_allowed = 0
      end
      for each object with label all_flags do -- reject spawn points if a flag they've spawned is still on the map
         if current_object.spawned_from == selected_spawn then 
            spawn_allowed = 0
         end
      end
      if spawn_allowed == 1 or flag_spawn_timeout.is_zero() then 
         fallback_spawn = no_object
         for each object with label "flag_spawn_loc" do
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
         created_flag.set_pickup_permissions(no_one)
         created_flag.points = selected_spawn.spawn_sequence
         if selected_spawn.spawn_sequence > 1 then 
            created_vfx = no_object
            created_vfx = selected_spawn.place_at_me(particle_emitter_fire, none, never_garbage_collect, 0, 0, 0, none)
            created_vfx.attach_to(created_flag, 0, 0, 6, absolute)
            created_flag.set_scale(125)
         end
         created_flag.set_shape(sphere, 10) -- pickup radius
         created_flag.team = neutral_team
         created_flag.spawned_from = selected_spawn
      end
   end
end

for each player do -- manage flag pickup, drop, and carrier traits
   script_widget[0].set_visibility(current_player, false)
   for each object with label all_flags do -- flag pickup
      if  current_object.carrier == no_player
      and current_object.is_carried == 0
      and current_player.carried_flag_count <= 6
      and current_object.shape_contains(current_player.biped)
      then 
         current_player.carried_flag_count += 1
         current_object.is_carried = 1
         current_object.carrier    = current_player
         current_object.attach_to(current_player.biped, 0, 0, 5, absolute)
         current_object.team = current_player.team
      end
   end
   if current_player.killer_type_is(guardians | suicide | kill | betrayal | quit) then -- drop flags on death
      current_player.carried_flag_count = 0
      for each object with label all_flags do
         if current_object.carrier == current_player then 
            current_object.detach()
            current_object.carrier    = no_player
            current_object.is_carried = 0
            --
            -- We want to make sure the flag lands upright, I guess?
            --
            global.object[0] = no_object
            global.object[0] = get_random_object("speedpile_goal", no_object)
            current_object.copy_rotation_from(global.object[0], false)
            --
            current_object.team = neutral_team
            if current_object.points > 1 then 
               current_object.set_scale(125)
            end
         end
      end
   end
   if current_player.carried_flag_count != 0 then 
      current_player.apply_traits(carrier_traits)
      script_widget[0].set_visibility(current_player, true)
   end
end

on object death: if killed_object.is_carried == 1 then 
   for each player do
      if current_player == killed_object.carrier then 
         current_player.carried_flag_count -= 1
      end
   end
end

if game.round_time_limit > 0 and game.round_timer.is_zero() then -- round timer
   game.end_round()
end
