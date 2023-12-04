

char listweapons[][] = {
	"defaultsound",
	"henryrifle",
	"xbow",
	"x_arrow",
	"whiskey2",
	"whiskey",
	"walker2",
	"walker",
	"volcanic2",
	"volcanic",
	"spencer",
	"shotgun",
	"sharps",
	"schofield2",
	"schofield",
	"sawedoff_shotgun2",
	"sawedoff_shotgun",
	"remington_army2",
	"remington_army",
	"peacemaker2",
	"peacemaker",
	"mauser2",
	"mauser",
	"maresleg2",
	"maresleg",
	"machete",
	"thrown_machete",
	"hammerless2",
	"hammerless",
	"ghostgun2",
	"ghostgun",
	"fists_ghost",
	"fists",
	"dynamite_black",
	"dynamite_belt",
	"dynamite_yellow",
	"dynamite",
	"deringer2",
	"deringer",
	"coltnavy2",
	"coltnavy",
	"coachgun",
	"carbine",
	"knife",
	"thrown_knife",
	"bow",
	"arrow",
	"axe",
	"thrown_axe",
	"kick"
}


KeyValues kv;

#include <sdktools>

public void OnPluginStart()
{
	HookEvent("player_death", player_death);
}


public void OnConfigsExecuted()
{
	if(kv != null)
		delete kv;

	kv = new KeyValues("sample");

	char soundfile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, soundfile, sizeof(soundfile), "configs/fragkillsound.txt");

	if(!kv.ImportFromFile(soundfile))
	{
		SetFailState("Missing KeyValue file: \"configs/fragkillsound.txt\"");
	}

	char buffer[PLATFORM_MAX_PATH];

	for(int x = 0; x < sizeof(listweapons); x++)
	{

		if(!kv.JumpToKey(listweapons[x]))
			continue;

		kv.Rewind();

		kv.GetString(listweapons[x], buffer, sizeof(buffer));

		if(strlen(buffer) < 5)
			continue;

		PrecacheSound(buffer);

		Format(buffer, sizeof(buffer), "sound/%s", buffer);
		AddFileToDownloadsTable(buffer);
		//PrintToServer("%s", buffer);
	}
}


public void player_death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if(!attacker || !IsClientInGame(attacker))
		return;

	char weapon[35];
	event.GetString("weapon", weapon, sizeof(weapon));

	if(!kv.JumpToKey(weapon))
			return;

	kv.Rewind();

	char buffer[PLATFORM_MAX_PATH];
	kv.GetString(weapon, buffer, sizeof(buffer));

	if(strlen(buffer) < 5)
	{
		kv.GetString(listweapons[0], buffer, sizeof(buffer));
	}

	//PrintToServer("%s", buffer);

	//EmitSoundToAll(buffer, attacker);
	EmitSoundToAll(buffer); // all players can hear clearly

	//PrintToChatAll("attacker %N", attacker);

}

/*


Server event "player_team", Tick 1081:
- "userid" = "2"
- "team" = "1"
- "oldteam" = "0"
- "disconnect" = "0"
- "autoteam" = "1"
- "silent" = "1"
- "name" = "'Bacardi"
L 02/17/2022 - 12:27:43: "'Bacardi<2><[U:1:28327177]><Unassigned>" joined team "Spectator"
Server event "player_connect_fof", Tick 1081:
- "userid" = "2"
Server event "player_activate", Tick 1081:
- "userid" = "2"
L 02/17/2022 - 12:27:43: "'Bacardi<2><[U:1:28327177]><>" entered the game
Server event "break_prop", Tick 1082:
- "entindex" = "367"
- "userid" = "0"















Server event "player_shoot", Tick 5968:
- "userid" = "2" (local)
- "weapon" = "volcanic" (local)
- "mode" = "2" (local)
- "pellets" = "" (local)
Server event "player_hurt", Tick 5968:
- "userid" = "4"
- "attacker" = "2"
- "weapon" = "volcanic" (local)
- "health" = "8"
- "damage" = "45"
- "hitgroup" = "1"
L 02/16/2022 - 22:29:41: "'Bacardi<2><[U:1:28327177]><Vigilantes>" triggered "combat" (notoriety "16")
Server event "player_death", Tick 5968:
- "userid" = "4"
- "attacker" = "2"
- "weapon" = "volcanic"
- "headshot" = "1"
- "assist" = "0"
- "damagebits" = "4354"
- "penetration" = "0"
- "index" = "30"
L 02/16/2022 - 22:29:41: "'Bacardi<2><[U:1:28327177]><Vigilantes>" killed "BOT Django<4><BOT><Bandidos>" with "volcanic" (headshot) (attacker_position "707 -215 70") (victim_position "718 -142 71")
Server event "entity_killed", Tick 5968:
- "entindex_killed" = "3"
- "entindex_attacker" = "1"
- "entindex_inflictor" = "1"
- "damagebits" = "4354"



- worldspawn
'skill_manifest.cfg' not present; not executing.
Executing dedicated server config file server.cfg
Server logging enabled.
L 02/17/2022 - 23:23:27: Log file closed.
Server logging data to file logs\L0217003.log
L 02/17/2022 - 23:23:27: Log file started (file "logs\L0217003.log") (game "G:\server\fistful of frags\fof") (version "0")
Writing cfg/banned_ip.cfg.
Writing cfg/banned_user.cfg.
- team_manager
- team_manager
- team_manager
- team_manager
- team_manager
- team_manager
- team_manager
- soundent
- player_manager
- hl2mp_gamerules
- bodyque
- bodyque
- bodyque
- bodyque
- fof_ghost
- ai_network
- item_healthvial
- item_healthkit
- item_battery
- weapon_henryrifle
- weapon_xbow
- x_arrow
- weapon_whiskey2
- weapon_whiskey
- weapon_walker2
- weapon_walker
- weapon_volcanic2
- weapon_volcanic
- weapon_spencer
- weapon_shotgun
- weapon_sharps
- weapon_schofield2
- weapon_schofield
- weapon_sawedoff_shotgun2
- weapon_sawedoff_shotgun
- weapon_remington_army2
- weapon_remington_army
- weapon_peacemaker2
- weapon_peacemaker
- weapon_mauser2
- weapon_mauser
- weapon_maresleg2
- weapon_maresleg
- weapon_machete
- thrown_machete
- weapon_hammerless2
- weapon_hammerless
- weapon_ghostgun2
- weapon_ghostgun
- weapon_fists_ghost
- weapon_fists
- weapon_dynamite_black
- dynamite_black
- weapon_dynamite_belt
- dynamite_yellow
- weapon_dynamite
- dynamite
- weapon_deringer2
- weapon_deringer
- weapon_coltnavy2
- weapon_coltnavy
- weapon_coachgun
- weapon_carbine
- weapon_knife
- thrown_knife
- weapon_bow
- arrow
- weapon_axe
- thrown_axe
- item_xbow_spawn
- item_golden_skull
- item_potion
- item_whiskey
- vgui_screen
- team_round_timer
- spraycan
- entityflame
- light
- env_sprite
- prop_physics_respawnable
- light
- env_sprite
- light
- env_sprite
- light
- env_sprite
- light
- env_sprite
- light
- env_sprite
- light
- env_sprite
- prop_physics_respawnable
- light
- env_sprite
- prop_physics_override
- prop_physics_override
- keyframe_rope
- infodecal
- infodecal
- func_breakable_surf
- func_breakable_surf
- light_spot
- light_spot
- light
- light
- env_sprite
- prop_physics_respawnable
- prop_physics_respawnable
- prop_physics_respawnable
- prop_physics_respawnable
- prop_physics_respawnable
- prop_physics_respawnable
- prop_physics_respawnable
- prop_physics_respawnable
- prop_physics_respawnable
- prop_physics_respawnable
- prop_physics_respawnable
- prop_physics_respawnable
- prop_physics_respawnable
- prop_physics_respawnable
- light
- env_sprite
- light
- env_sprite
- light
- env_sprite
- light_spot
- light_spot
- light
- light
- env_sprite
- light_spot
- light_spot
- light
- env_sprite
- light
- env_sprite
- prop_physics_multiplayer
- prop_physics_multiplayer
- prop_physics_multiplayer
- prop_physics_multiplayer
- prop_physics_multiplayer
- prop_dynamic_override
- prop_physics_respawnable
- prop_physics_respawnable
- env_soundscape
- env_soundscape
- env_soundscape
- prop_physics_multiplayer
- env_soundscape
- prop_physics_respawnable
- prop_dynamic_override
- prop_physics_multiplayer
- func_brush
- env_soundscape_proxy
- env_sprite
- light
- func_brush
- func_brush
- light
- env_sprite
- func_brush
- func_brush
- light
- infodecal
- infodecal
- infodecal
- infodecal
- infodecal
- infodecal
- infodecal
- light
- light
- env_sprite
- light
- env_sprite
- light
- light
- env_sprite
- light_spot
- light_spot
- light
- env_sprite
- prop_door_rotating
- prop_physics_respawnable
- prop_physics_respawnable
- func_brush
- prop_physics_respawnable
- move_rope
- keyframe_rope
- prop_physics_respawnable
- prop_physics_respawnable
- prop_physics_respawnable
- prop_physics_respawnable
- env_soundscape_proxy
- info_player_fof
- func_brush
- prop_physics_respawnable
- prop_physics
- prop_physics
- env_soundscape
- prop_physics
- prop_physics
- prop_physics
- func_brush
- prop_dynamic_override
- prop_dynamic_override
- func_door_rotating
- light_spot
- light_spot
- light
- light
- env_sprite
- light
- env_sprite
- prop_door_rotating
- prop_door_rotating
- prop_physics
- prop_physics
- prop_physics
- env_sprite
- light
- light
- env_sprite
- light
- env_sprite
- env_sprite
- light
- env_sprite
- env_sprite
- light_spot
- light_spot
- light
- light
- env_sprite
*/