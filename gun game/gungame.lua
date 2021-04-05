
declare global.number[0] with network priority local
declare global.number[1] with network priority local
declare global.number[2] with network priority local
declare global.number[3] with network priority local
declare global.number[4] with network priority local
declare global.object[0] with network priority local
declare global.object[1] with network priority local
declare global.player[0] with network priority high
declare global.player[1] with network priority high
declare player.number[0] with network priority local
declare player.number[1] with network priority low
declare player.number[2] with network priority low
declare player.object[0] with network priority low
declare player.timer[0] = 5
declare player.timer[1] = 8

-- This should be the index of a nameless Forge label whose object type 
-- is the fire particle emitter:
alias all_fire_particles = 4

-- This should be the index of a nameless Forge label whose object type 
-- is the skull:
alias all_skulls = 5

alias lifespan = object.timer[0]

if game.teams_enabled == 1 then 
   for each object with label "ffa_only" do
      current_object.delete()
   end
end

if game.teams_enabled == 0 then 
   for each object with label "team_only" do
      current_object.delete()
   end
end

on init: do
   
end

for each player do
   if current_player.is_elite() then 
      current_player.set_loadout_palette(elite_tier_1)
   end
   if not current_player.is_elite() then 
      current_player.set_loadout_palette(spartan_tier_1)
   end
end

for each player do
   current_player.set_round_card_title("Kills earn you a new weapon.\nGet a kill with every weapon to win!", game.score_to_win)
end

for each player do
   current_player.timer[0].set_rate(-100%)
   current_player.timer[1].set_rate(-100%)
   if current_player.number[1] == 0 and current_player.timer[0].is_zero() then 
      send_incident(custom_game_start, current_player, no_player)
      current_player.number[1] = 1     
   end

   if current_player.number[2] == 0 and current_player.timer[1].is_zero() then 
      game.play_sound_for(all_players, inv_cue_spartan_win_1, true)
      current_player.number[2] = 1
   end
end

for each player do
   global.number[1] = 0
   current_player.script_stat[0] = current_player.rating
   current_player.number[0] = 0
   if game.teams_enabled == 1 then 
      global.number[1] = current_player.team.get_scoreboard_pos()
   end
   if game.teams_enabled == 0 then 
      global.number[1] = current_player.get_scoreboard_pos()
   end
   if global.number[1] == 1 and not current_player.score == 0 then 
      current_player.number[0] = 1
   end
end

if script_option[0] == 3 or script_option[0] == 7 then 
   for each object with label 1 do
      current_object.delete()
   end
end

for each player do
   global.number[1] = 0
   global.object[0] = current_player.biped
   if global.object[0] != no_object then 
      current_player.object[0] = global.object[0]
   end
   if current_player.killer_type_is(guardians | suicide | kill | betrayal | quit) then 
      current_player.score += script_option[2]
      if current_player.killer_type_is(kill) then 
         global.player[0] = current_player.try_get_killer()         
         global.player[1] = current_player
         if global.player[0].score < 19 then
            global.player[0].score += script_option[1]
         end
         do
            global.number[2] = 0
            global.number[3] = 0
            global.number[3] = current_player.try_get_death_damage_type()
            if global.number[3] == 6 then 
               global.number[2] = current_player.object[0].get_distance_to(global.player[0].object[0])
               if global.number[2] > 400 then 
                  send_incident(dlc_achieve_5, global.player[0], current_player)
               end
            end
         end
         global.number[0] = current_player.try_get_death_damage_mod()
         global.number[1] = global.player[0].get_spree_count()
         do
            global.number[1] %= 5
            if global.number[1] == 0 then 
               global.player[0].score += script_option[11]
            end
         end
         if current_player.number[0] == 1 then 
            global.player[0].score += script_option[5]
         end
         if global.number[0] == 1 then -- melee
            if global.player[0].score >= 19 then
               global.player[0].score = 10000
            end
            if global.player[0].score < 19 and global.player[0].score != 6 and global.player[0].score != 10 then
               global.player[0].score -= 1
               current_player.score  -= 1
               game.show_message_to(all_players, timer_beep, "%s score reduced!", global.player[1])
               if current_player.score == 18 then
                  script_widget[0].set_text("")
               end
            end
            
         end
         if global.number[0] == 2 then -- assassination
            if global.player[0].score >= 19 then
               global.player[0].score = 10000
            end
            if global.player[0].score < 19 then
               global.player[0].score -= 1
               current_player.score -= 1
               game.show_message_to(all_players, timer_beep, "%s score reduced!", global.player[1])
               global.timer[0].reset()
               if current_player.score == 18 then
                  script_widget[0].set_text("")
               end
            end
         end
         if global.number[0] == 3 then 
            global.player[0].score += script_option[9]
         end
         if global.number[0] == 4 then 
            global.player[0].score += script_option[10]
         end
         if global.number[0] == 5 then 
            global.player[0].score += script_option[6]
         end
         
         global.player[0].biped.remove_weapon(secondary, true)
         global.player[0].biped.remove_weapon(primary, true)
         
         if global.player[0].score == 19 then
            send_incident(40_in_a_row, global.player[0], no_player)
            game.play_sound_for(all_players, inv_cue_spartan_win_2, true)
         end
         if global.player[0].score < 19 then
            send_incident(respawn_tick_final, global.player[0], no_player)  
         end
      end
   end
end

for each player do
   if current_player.killer_type_is(suicide | kill | betrayal | quit | guardians) and not current_player.killer_type_is(kill) and not current_player.killer_type_is(betrayal) then 
      current_player.score += script_option[3]
   end
end

for each player do
   if current_player.killer_type_is(betrayal) then 
      global.player[0] = current_player.try_get_killer()
      global.player[0].score += script_option[4]
   end
end

if game.round_time_limit > 0 and game.round_timer.is_zero() then 
   game.end_round()
end

for each player do
   if current_player.score == 19 then 
      current_player.apply_traits(script_traits[0])
   end
end


for each player do
   if current_player.score <= 0 then
      current_player.biped.add_weapon(assault_rifle, force)
   end
   if current_player.score == 1 then
      current_player.biped.add_weapon(concussion_rifle, force)
   end
   if current_player.score == 2 then
      current_player.biped.add_weapon(shotgun, force)
   end
   if current_player.score == 3 then
      current_player.biped.add_weapon(needler, force)
   end
   if current_player.score == 4 then
      current_player.biped.add_weapon(sniper_rifle, force)
   end
   if current_player.score == 5 then
      current_player.biped.add_weapon(gravity_hammer, force)
   end
   if current_player.score == 6 then
      current_player.biped.add_weapon(rocket_launcher, force)
   end
   if current_player.score == 7 then
      current_player.biped.add_weapon(plasma_rifle, force)
   end
   if current_player.score == 8 then
      current_player.biped.add_weapon(magnum, force)
   end
   if current_player.score == 9 then
      current_player.biped.add_weapon(energy_sword, force)
   end
   if current_player.score == 10 then
      current_player.biped.add_weapon(dmr, force)
   end
   if current_player.score == 11 then
      current_player.biped.add_weapon(needle_rifle, force)
   end
   if current_player.score == 12 then
      current_player.plasma_grenades = 1
   alt
      current_player.plasma_grenades = 0
   end
   if current_player.score == 13 then
      current_player.biped.add_weapon(plasma_repeater, force)
   end
   if current_player.score == 14 then
      current_player.biped.add_weapon(spartan_laser, force)
   end
   if current_player.score == 15 then
      current_player.biped.add_weapon(focus_rifle, force)
   end
   if current_player.score == 16 then
      current_player.biped.add_weapon(plasma_launcher , force)
   end
   if current_player.score == 17 then
      current_player.biped.add_weapon(spiker, force)
   end
   if current_player.score == 18 then
      current_player.biped.add_weapon(plasma_pistol, force)
   end
   if current_player.score == 19 then
      global.object[1] = current_player.get_weapon(primary)
      if not global.object[1].is_of_type(skull) then
         current_player.biped.add_weapon(skull, force)
      end
      global.number[4] = 0
      global.number[4]  = rand(10)
      if global.number[4] <= 2 then -- 30% chance to spawn a particle emitter
         current_player.biped.place_at_me(particle_emitter_fire, none, never_garbage_collect, 0, 0, 0, none)
      end
      current_player.biped.set_waypoint_visibility(everyone)
      current_player.biped.set_waypoint_icon(crown)
      current_player.biped.set_waypoint_timer(none)
      current_player.biped.set_waypoint_priority(high)
      script_widget[0].set_text("%s is about to win!\nDon't let them melee you!", current_player)
   alt
      current_object.set_scale(100)
      current_player.biped.set_waypoint_visibility(no_one)
   end
end


for each object with label all_fire_particles do -- clean up super shields VFX
   current_object.lifespan.set_rate(-100%)
   if current_object.lifespan.is_zero() then 
      current_object.delete()
   end
end

for each object with label all_skulls do -- clean up skulls
   global.player[0] = current_object.get_carrier()
   if global.player[0] == no_player then
      current_object.delete()
   end
end