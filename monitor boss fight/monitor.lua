alias max_zombie_count = script_option[0]
alias last_man_standing = script_option[1]
alias safe_havens = script_option[2]
alias haven_time_limit = script_option[3]
alias zombie_victory = script_option[4]
alias survivor_victory = script_option[5]
alias haven_points = script_option[6]
alias kill_points = script_option[7]
alias suicide_points = script_option[8]
alias betrayal_points = script_option[9]
alias zombie_kill_points = script_option[10]
alias last_man_standing_points = script_option[11]
alias suicide_becomes_zombie = script_option[12]

alias last_man_standing_announced = global.number[0]
alias first_hill_moved = global.number[1]
alias monitor_downs = global.number[2]
--- 
alias current_zombie_count = global.number[3]
alias debug_zombie = global.number[4]
alias monitor_danger_distance = global.number[5]
alias monitor_shields = global.number[6]
alias rng = global.number[7]
alias final_stage = global.number[8]
alias down_time = global.number[9]
alias shields_amount = global.number[10]
alias temp_num_1 = global.number[11]

alias current_hill = global.object[0]
alias prev_hill = global.object[1]
alias monitor_aimer_ref = global.object[4]
alias monitor_aimer = global.object[5]
alias temp_obj_2 = global.object[6]
alias temp_obj_1 = global.object[7]

alias temp_player_1 = global.player[0]
alias temp_player_2 = global.player[1]
alias monitor_player = global.player[2]

alias is_zombie = player.number[0]
alias is_last_man_standing = player.number[1]
alias is_in_haven = player.number[2]

alias alive_timer = player.timer[2]
alias ability_timer = player.timer[3]

alias haven_assigned_timer = object.timer[0]

alias haven_timer = global.timer[0]
alias start_timer = global.timer[1]
alias ball_reset_timer = global.timer[2]
alias monitor_disabled_timer = global.timer[3]
alias despawn_timer = global.timer[4]

alias has_been_entered = object.number[1]

declare last_man_standing_announced with network priority low
declare first_hill_moved with network priority local
declare monitor_downs with network priority low
declare current_zombie_count with network priority local
declare debug_zombie with network priority local = 0 -- enable to test with zombie
declare monitor_shields with network priority high
declare monitor_danger_distance with network priority high
declare down_time with network priority high
declare shields_amount with network priority high
declare rng with network priority high
declare final_stage with network priority low
declare temp_num_1 with network priority local

declare current_hill with network priority low
declare prev_hill with network priority local
declare monitor_aimer_ref with network priority local
declare monitor_aimer with network priority local
declare temp_obj_1 with network priority local
declare temp_obj_2 with network priority local

declare temp_player_1 with network priority local
declare temp_player_2 with network priority local

declare monitor_player with network priority high

declare haven_timer = haven_time_limit
declare start_timer = 10
declare ball_reset_timer = 1
declare player.is_zombie with network priority low

declare player.is_last_man_standing with network priority low
declare player.is_in_haven with network priority low = 1
declare player.number[3] with network priority low
declare player.alive_timer = 1
declare player.ability_timer = script_option[13]
declare monitor_disabled_timer = script_option[14]
declare despawn_timer = 25

declare object.has_been_entered with network priority low
declare object.haven_assigned_timer = haven_time_limit


function make_new_hill()
   rng = rand(3)
   haven_timer.set_rate(0%)
   haven_timer = haven_time_limit
   haven_timer.reset()
   current_hill.set_waypoint_visibility(no_one)
   current_hill.set_shape_visibility(no_one)
   current_hill.set_waypoint_timer(none)
   current_hill.has_been_entered = 0
   prev_hill = current_hill
   current_hill = no_object
   current_hill = get_random_object("inf_haven", prev_hill)
end

do
   alias player_count_less_1 = temp_num_1
   current_zombie_count = 0
   player_count_less_1 = -1
   for each player do
      player_count_less_1 += 1
      if current_player.is_zombie == 1 then 
         current_zombie_count += 1
      end
   end
   for each player randomly do
      if current_zombie_count < max_zombie_count and current_zombie_count < player_count_less_1 and current_player.is_last_man_standing != 1 and current_player.is_zombie != 1 then 
         current_player.is_zombie = 1
         current_zombie_count += 1
      altif debug_zombie == 1 then
         current_player.is_zombie = 1
         current_zombie_count += 1
      end
   end
   for each player do
      if current_player.is_zombie == 1 and current_player.team != team[1] then 
         send_incident(inf_new_zombie, current_player, no_player)
         current_player.team = team[1]
         current_player.apply_traits(script_traits[0])
         current_player.biped.kill(true)
      end
   end
end

for each player do
   for each player do
      if current_player.team == team[0] then 
         current_player.set_round_card_title("Kill 343 Guilty Spark and\nactivate Halo!")
      end
      if current_player.team == team[1] then 
         current_player.set_round_card_title("Kill the reclaimers!\nUse jetpack to drop fusion coils.\nDon't move too far from the center.")
      end
   end
end

for each player do
   current_player.team = team[0]
   if current_player.is_zombie == 1 then 
      current_player.team = team[1]
      current_player.apply_traits(script_traits[0])

      if current_player.biped != no_object and not current_player.biped.is_of_type(monitor) then
         temp_obj_1 = current_player.biped
         temp_obj_2 = current_player.biped.place_at_me(monitor, none, none, 0, 0, 5, none)

         current_player.set_biped(temp_obj_2)
         temp_obj_1.delete()

         current_player.biped.remove_weapon(secondary, true)
         current_player.biped.remove_weapon(primary, true)
         current_player.biped.add_weapon(focus_rifle, force)
         temp_obj_2 = current_player.biped.place_at_me(jetpack, none, never_garbage_collect, 0, 0, 0, none)
         current_player.biped.set_scale(225)
         current_player.biped.set_waypoint_icon(bullseye)
         current_player.biped.set_waypoint_priority(high)
         current_player.biped.set_waypoint_visibility(everyone)
         current_player.biped.set_waypoint_range(0, 100)

         temp_obj_1 = current_player.biped.place_at_me(sound_emitter_alarm_1, none, never_garbage_collect, 0, 0, 0, none)
         temp_obj_1.attach_to(current_player.biped, 0, 0, 0, relative)

         monitor_player = current_player
         monitor_player.biped.shields = 100
         shields_amount = 100
      end

   end
end

for each player do
   if current_player.killer_type_is(guardians | suicide | kill | betrayal | quit) then 
      alias kilee_player = temp_player_2
      alias killed_player = temp_player_1
         
      current_player.is_last_man_standing = 0
      killed_player = current_player
      kilee_player = no_player
      kilee_player = current_player.try_get_killer()
      if current_player.killer_type_is(kill) and killed_player.is_zombie == 1 and killed_player.is_zombie != kilee_player.is_zombie then 
         kilee_player.score += kill_points
         send_incident(zombie_kill_kill, kilee_player, killed_player)
         game.play_sound_for(all_players, inv_cue_spartan_win_big, true)
      end
      if current_player.killer_type_is(kill) and safe_havens == 1 and killed_player.is_zombie == 1 and killed_player.is_zombie != kilee_player.is_zombie and kilee_player.is_in_haven == 1 then 
         kilee_player.score += haven_points
      end
      if current_player.killer_type_is(kill) and not kilee_player == no_player and killed_player.is_zombie == 0 then 
         killed_player.is_zombie = 1
         send_incident(infection_kill, kilee_player, killed_player)
         kilee_player.score += zombie_kill_points
         kilee_player.script_stat[1] += 1
         temp_obj_1 = monitor_player.biped
         temp_obj_1.shields += 25
      end
      if current_player.killer_type_is(suicide) then 
         kilee_player.score += suicide_points
         if suicide_becomes_zombie == 1 then 
            killed_player.is_zombie = 1
         end
      end
      if current_player.killer_type_is(betrayal) and killed_player.is_zombie == kilee_player.is_zombie then 
         kilee_player.score += betrayal_points
      end
      
      -- special condition not working
      if current_player.killer_type_is(guardians) then 
         kilee_player = monitor_player
         kilee_player.score += kill_points
         killed_player.is_zombie = 1
         send_incident(zombie_kill_kill, kilee_player, killed_player) 
      end
   end
end

if safe_havens == 1 and current_hill == no_object then 
   current_hill = get_random_object("inf_haven", prev_hill)
   if first_hill_moved == 1 then 
      send_incident(hill_moved, all_players, all_players)
   end
   first_hill_moved = 1
end

if safe_havens == 1 and haven_timer.is_zero() then 
   make_new_hill()
end

do
   current_hill.set_waypoint_visibility(everyone)
   current_hill.set_waypoint_icon(crown)
   current_hill.set_shape_visibility(everyone)
   current_hill.set_waypoint_priority(normal)
end

if safe_havens == 1 then 
   for each player do
      if current_hill.shape_contains(current_player.biped) and current_player.is_zombie == 0 and current_hill.has_been_entered == 0 then 
         haven_timer.set_rate(-100%)
         current_hill.has_been_entered = 1 
      end

   end
   if current_hill.has_been_entered == 1 then 
      current_hill.haven_assigned_timer = haven_timer
      current_hill.set_waypoint_timer(0)
      if current_hill.haven_assigned_timer < 6 then 
         current_hill.set_waypoint_priority(blink)
      end
   end
end

if last_man_standing == 1 then 
   current_zombie_count = 0
   if global.number[0] == 0 then 
      for each player do
         if not current_player.is_zombie == 1 then 
            current_zombie_count += 1
         end
      end
      if current_zombie_count == 1 then 
         for each player do
            if not current_player.is_zombie == 1 then 
               current_player.apply_traits(script_traits[1])
               current_player.biped.set_waypoint_icon(skull)
               current_player.biped.set_waypoint_priority(normal)
               current_player.is_last_man_standing = 1
               current_player.score += last_man_standing_points
               send_incident(inf_last_man, current_player, all_players)
            end
         end
         global.number[0] = 1
      end
   end
end

for each player do
   if current_player.is_last_man_standing == 1 then 
      current_player.apply_traits(script_traits[1])
   end
end

for each player do
   current_player.is_in_haven = 0
   if safe_havens == 1 and current_player.is_zombie == 0 then 
      script_widget[0].set_text("New hill - %s", haven_timer)
      script_widget[0].set_visibility(current_player, true)   
      if current_hill.shape_contains(current_player.biped) then
         current_player.is_in_haven = 1
         current_player.apply_traits(script_traits[2])

         if final_stage == 1 then
            current_player.biped.add_weapon(spartan_laser, force)
         alt
            if rng == 0 then
               current_player.biped.add_weapon(dmr, force)
            altif rng == 1 then
               current_player.biped.add_weapon(sniper_rifle, force)
            altif rng == 2 then
               current_player.biped.add_weapon(assault_rifle, force)
            end
         end
         
      alt
         current_player.biped.remove_weapon(primary, true)
         current_player.biped.remove_weapon(secondary, true)
      end
   end
end

do
   start_timer.set_rate(-100%)
   if start_timer.is_zero() then 
      current_zombie_count = 0
      for each player do
         if current_player.is_zombie == 0 then 
            current_zombie_count += 1
         end
      end
      for each player do
         if current_zombie_count == 1 and current_player.is_zombie == 0 and current_player.killer_type_is(suicide) then 
            current_zombie_count = 0
         end
      end
      if current_zombie_count == 0 and debug_zombie == 0 then 
         send_incident(infection_zombie_win, all_players, all_players)
         for each player do
            if current_player.is_last_man_standing != 1 and current_player.is_zombie == 1 then 
               current_player.score += zombie_victory
            end
         end
         game.end_round()
      end
   end
end

if game.round_timer.is_zero() and game.round_time_limit > 0 then 
   current_zombie_count = 0
   for each player do
      if current_player.is_zombie == 0 then 
         current_zombie_count += 1
      end
   end
   if not current_zombie_count == 0 then 
      send_incident(infection_survivor_win, all_players, all_players)
      for each player do
         if current_player.is_zombie == 0 then 
            current_player.score += survivor_victory
         end
      end
   end
   game.end_round()
end


do 
   ball_reset_timer.set_rate(-100%)
   for each object with label "monitor_aimer_marker" do
      current_object.set_invincibility(1)
      current_object.set_garbage_collection_disabled(1)
      if monitor_player != no_player then
         monitor_player.ability_timer.set_rate(-100%)
         temp_obj_1 = monitor_player.get_armor_ability()
         if temp_obj_1.is_of_type(jetpack) and temp_obj_1.is_in_use() and monitor_player.ability_timer.is_zero() and final_stage == 0 then
            temp_obj_1 = current_object.place_at_me(fusion_coil, none, never_garbage_collect, 0, 0, -8, none)
            temp_obj_1.push_upward()
            monitor_player.ability_timer.reset()
            game.play_sound_for(all_players, timer_beep, true)
         end   

         if monitor_player.ability_timer.is_zero() and final_stage == 0 then
            current_object.team = team[1]
            current_object.set_shape_visibility(allies)
            current_object.set_waypoint_icon(inward)
            current_object.set_waypoint_visibility(allies)
            current_object.set_waypoint_priority(normal)
         alt
            current_object.set_shape_visibility(no_one)
            current_object.set_waypoint_visibility(no_one)
         end 
         current_object.attach_to(monitor_player.biped, 80, 0, 40, relative)
         current_object.detach()
      end
   end


   for each object with label "monitor_center_point" do
      if monitor_player != no_player then
         monitor_danger_distance = current_object.get_distance_to(monitor_player.biped)
         monitor_danger_distance -= 45
         monitor_danger_distance *= -1
         if monitor_danger_distance < 0 and ball_reset_timer.is_zero() then --- radius 
            ball_reset_timer.reset()
            shields_amount = monitor_player.biped.shields
            shields_amount -= 20
            monitor_player.biped.shields = shields_amount
            monitor_player.biped.attach_to(current_object, 0, 0, 0, relative)
            monitor_player.biped.detach()
            send_incident(ball_reset, current_player, no_player)
            if final_stage == 1 then
               monitor_player.biped.health -= 50
            end
         end
         script_widget[2].set_text("Danger distance: %n", monitor_danger_distance)
      end
   end
end


for each player do
   if current_player.is_zombie == 0 then 
      current_player.alive_timer.set_rate(-100%)
      if current_player.alive_timer.is_zero() then 
         current_player.script_stat[0] += 1
         current_player.alive_timer.reset()
      end
      if start_timer.is_zero() then
         script_widget[1].set_visibility(current_player, true)
      alt
         script_widget[1].set_visibility(current_player, false)
      end
      script_widget[2].set_visibility(current_player, false)
   altif debug_zombie == 1 then
      script_widget[1].set_visibility(current_player, true)
      script_widget[2].set_visibility(current_player, true)
   alt
      script_widget[1].set_visibility(current_player, false)
      script_widget[2].set_visibility(current_player, true)
   end

   
end

do
   if monitor_player != no_player then
      monitor_shields = monitor_player.biped.shields
      if monitor_shields <= 0 then
         if final_stage == 0 then
            monitor_disabled_timer.set_rate(-100%)
            monitor_downs += 1
            down_time = monitor_downs
            down_time *= 2 -- 2x downs
            down_time += 3 --- +min
            monitor_shields = rand(7) --- +extra
            down_time += monitor_shields
            monitor_disabled_timer = down_time
            ---monitor_disabled_timer.reset() 
            game.show_message_to(all_players, boneyard_generator_power_down, "Monitor is down!")
            make_new_hill()
         end
         final_stage = 1
         monitor_player.biped.remove_weapon(primary, true)
         monitor_player.biped.remove_weapon(secondary, true)   
         monitor_player.apply_traits(script_traits[3])
         script_widget[1].set_text("\nFinish him with the laser! (%s)", monitor_disabled_timer)
         set_scenario_interpolator_state(1, 1)
      alt
         final_stage = 0
         script_widget[1].set_text("\nMonitor shields: %n/%n", monitor_shields, 100)
         set_scenario_interpolator_state(1, 0)
         temp_num_1 = monitor_player.biped.get_speed()
         if temp_num_1 > 15 then
            monitor_player.biped.remove_weapon(primary, true)
            monitor_player.biped.remove_weapon(secondary, true)   
         alt
            monitor_player.biped.add_weapon(focus_rifle, force)
         end
      end
      script_widget[1].set_meter_params(number, monitor_shields, 100)

      if monitor_disabled_timer.is_zero() and final_stage == 1 then
         shields_amount = 75
         monitor_player.biped.shields = shields_amount
         make_new_hill()
         final_stage = 0
      end

      
   end
end

despawn_timer.set_rate(-100%)
if despawn_timer.is_zero() then
   for each object with label "despawn_me" do
      current_object.delete()
   end
end

for each object with label "halo_ring" do
   current_object.set_shape_visibility(everyone)
end
