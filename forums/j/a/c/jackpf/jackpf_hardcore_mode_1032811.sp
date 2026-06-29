//sdk tools
#include <sourcemod>
#include <sdktools>

//plugin version
#define PLUGIN_VERSION "2.3.0"

//plugin info
public Plugin:myinfo = 
{
	name		= "Jackpf's HardCore Mode",
	author		= "jackpf",
	description	= "HardCore modes",
	version		= PLUGIN_VERSION,
	url			= "http://jackpf.co.uk"
}

//cvar handles
new Handle:HardCore_Mode = INVALID_HANDLE;
new bool:setup = false;

//plugin setup
public OnPluginStart()
{
	//require Left 4 Dead 2
	decl String:Game[64];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "left4dead2", false))
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	
	//register cvars
	HardCore_Mode = CreateConVar("l4d2_HardCore_Mode", "0", "HardCore Mode.", FCVAR_NOTIFY | FCVAR_PLUGIN);
	CreateConVar("l4d2_HardCore_Version", PLUGIN_VERSION, "HardCore version.", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY);
	
	//register cmds
	RegConsoleCmd("sm_hardcore_info", HardCore_Info);
	
	//event hooks
	HookEvent("round_start", HardCore_Mode_Hook); //execute hardcore methods
	HookConVarChange(HardCore_Mode, HardCore_Mode_Hook2); //same as round start hook
}

//mode info
public Action:HardCore_Info(client, args)
{
	new Handle:Info = CreatePanel();
	
	SetPanelTitle(Info, "HardCore Info");
	
	DrawPanelText(Info, "-All modes:");
	DrawPanelText(Info, "	Tank & witch every level, with increased HP and damage.");
	DrawPanelText(Info, "	Black and white triggered on first incap.");
	DrawPanelText(Info, "	Modes are incremental.");
	
	DrawPanelText(Info, "-Mode 1:");
	DrawPanelText(Info, "	Replaces kits/defibs with pills.");
	
	DrawPanelText(Info, "-Mode 2:");
	DrawPanelText(Info, "	Replaces t2/3 weapons with t1 weapons, with limited ammo & pickups.");
	
	DrawPanelText(Info, "-Mode 3:");
	DrawPanelText(Info, "	Removes all health support.");
	
	SendPanelToClient(Info, client, _HardCore_Info, 20);
 
	CloseHandle(Info);
 
	return Plugin_Handled;

}
public _HardCore_Info(Handle:panel, MenuAction:action, param1, param2){}


//HardCore hooks
public Action:HardCore_Mode_Hook(Handle:event, const String:name[], bool:dontBroadcast)
{
	return HardCore_Mode_Realism();
}
public HardCore_Mode_Hook2(Handle:convar, const String:oldValue[], const String:newValue[])
{
	HardCore_Mode_Realism();
}

//HardCore methods
Action:HardCore_Mode_Realism()
{
	//if mode = any, turn on hardcore mode
	if(GetConVarInt(HardCore_Mode) >= 1)
	{
		//look for med kit type things...
		for(new i = 0; i <= GetEntityCount(); i++)
		{
			if(IsValidEntity(i))
			{
				decl String:EdictName[128];
				GetEdictClassname(i, EdictName, sizeof(EdictName));
				
				//if mode = 1 | 2, replace kits & defibs with pills
				if(GetConVarInt(HardCore_Mode) <= 2)
				{
					if(	StrContains(EdictName, "weapon_first_aid_kit", false) != -1 ||
						StrContains(EdictName, "weapon_defibrillator", false) != -1)
					{
						new index = CreateEntityByName("weapon_pain_pills_spawn");
						if(index != -1)
						{
							new Float:Angle[3];
							new Float:Location[3];
							
							GetEntPropVector(i, Prop_Send, "m_angRotation", Angle);
							GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location);
							
							TeleportEntity(index, Location, Angle, NULL_VECTOR);
							DispatchSpawn(index);
						}
						
						AcceptEntityInput(i, "Kill");
					}
				}
				//if mode = 3, delete everything :D
				else if(GetConVarInt(HardCore_Mode) >= 3)
				{
					if(	StrContains(EdictName, "weapon_first_aid_kit", false) != -1 ||
						StrContains(EdictName, "weapon_defibrillator", false) != -1 ||
						StrContains(EdictName, "weapon_pain_pills", false) != -1 ||
						StrContains(EdictName, "weapon_adrenaline", false) != -1)
					{
						AcceptEntityInput(i, "Kill");
					}
				}
			}
		}
		
		//setup some convars, only on first run
		if(!setup)
		{
			//increase survival bonus
			SetConVarInt(FindConVar("vs_survival_bonus"), GetConVarInt(FindConVar("vs_survival_bonus")) * 4);
			
			//give us a tank and a witch
			SetConVarFloat(FindConVar("versus_tank_chance"), 1.0, true);
			SetConVarFloat(FindConVar("versus_witch_chance"), 1.0, true);
			
			//hook some patches
			HookEvent("revive_success", HardCore_Mode_BW_Patch); //fix non-b&w screen
			HookEvent("heal_begin", HardCore_Mode_HealthKit_Patch); //fix bugged kit spawns
			HookEvent("spawner_give_item", HardCore_Mode_Weapon_Patch); //fix bugged weapon spawns
			HookEvent("player_incapacitated_start", HardCore_Mode_Witch_Patch); //mmm...
			HookEvent("tank_spawn", HardCore_Mode_Tank_Patch); //mmm²...
			SetConVarFloat(FindConVar("director_vs_convert_pills"), 0.0);
			
			setup = true;
		}
		
		//sort out weapons
		//HardCore_Mode_Weapons();
		//for some reason, unless a timer is applied, larger maps will crash replacing weapons
		//:/
		CreateTimer(1.0, HardCore_Mode_Weapons);
	}
	//otherwise, turn it off
	else
	{
		ResetConVar(FindConVar("vs_survival_bonus"));
		ResetConVar(FindConVar("versus_tank_chance"));
		ResetConVar(FindConVar("versus_witch_chance"));
		ResetConVar(FindConVar("director_vs_convert_pills"));
		//a map restart is required to restore weapons
		
		setup = false;
	}
	
	return Plugin_Handled;
}
public Action:HardCore_Mode_Weapons(Handle:timer)
{
	//if mode = 2 | 3, replace weapon spawns with tier 1 weapons
	if(GetConVarInt(HardCore_Mode) >= 2)
	{
		//allowed tier 1 weapons
		new String:t1_weapons[6][128] = {
		"weapon_shotgun_chrome",
		"weapon_pumpshotgun",
		"weapon_hunting_rifle",
		"weapon_smg",
		"weapon_smg",
		"weapon_smg_silenced"
		};
		
		//replace weapons
		for(new i = 0; i <= GetEntityCount(); i++)
		{
			decl String:EdictName[128];
			
			if(IsValidEntity(i))
			{
				GetEdictClassname(i, EdictName, sizeof(EdictName));
				
				if(	StrContains(EdictName, "weapon_spawn", false) != -1 || //all weapon spawns are called "weapon_spawn"
					StrContains(EdictName, "weapon_ammo_spawn", false) != -1) //remove ammo too
				{
					//get ent vectors
					decl Float:location[3], Float:angle[3];
					
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", location);
					GetEntPropVector(i, Prop_Send, "m_angRotation", angle);
					
					//remove the weapon spawn
					RemoveEdict(i);
					
					//create a new tier 1 weapon
					new index = CreateEntityByName(t1_weapons[GetRandomInt(0, sizeof(t1_weapons) - 1)]);
					TeleportEntity(index, location, angle, NULL_VECTOR);
					DispatchKeyValue(index, "count", "1"); //set the pickup limit to 1 ;) (can be hard for earlier maps, since there are normally 2 weapon spawns in the saferoom)
					DispatchSpawn(index); //<- this causes crashes!!!
					ActivateEntity(index);
					
					//restrict weapon ammo to 4 clips
					new Clip_Size = GetEntProp(index, Prop_Send, "m_iClip1");
					SetEntProp(index, Prop_Send, "m_iExtraPrimaryAmmo", Clip_Size * 3);
				}
			}
		}
	}
	
	return Plugin_Handled;
}

//patches
public Action:HardCore_Mode_HealthKit_Patch(Handle:event, const String:name[], bool:dontBroadcast)
{
	//if mode = any, we don't want kits...
	if(GetConVarInt(HardCore_Mode) >= 1)
	{
		new Client = GetClientOfUserId(GetEventInt(event, "userid")); //get userid of the player being naughty with a health kit
		
		if(IsClientConnected(Client))
		{
			new bugged_health_kit = GetPlayerWeaponSlot(Client, 3); //get his slot 4 weapon (index starts at 0)
			
			if(IsValidEntity(bugged_health_kit))
			{
				decl String:EdictName[128];
				GetEdictClassname(bugged_health_kit, EdictName, sizeof(EdictName));
				
				if(StrContains(EdictName, "weapon_first_aid_kit", false) != -1)
				{
					//remove his kit and give him pills instead
					RemovePlayerItem(Client, bugged_health_kit);
					GivePlayerItem(Client, "weapon_pain_pills");
				}
			}
		}
	}
	
	return Plugin_Handled;
}
public Action:HardCore_Mode_Weapon_Patch(Handle:event, const String:name[], bool:dontBroadcast)
{
	//if mode = 2 | 3, we do something with weapons..
	if(GetConVarInt(HardCore_Mode) >= 2)
	{
		new Client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if(IsClientConnected(Client))
		{
			new Weapon = GetPlayerWeaponSlot(Client, 0);
			
			if(IsValidEntity(Weapon))
			{
				decl String:EdictName[128];
				GetEdictClassname(Weapon, EdictName, sizeof(EdictName));
				
				new String:t1_weapons[6][128] = {
				"weapon_shotgun_chrome",
				"weapon_pumpshotgun",
				"weapon_hunting_rifle",
				"weapon_smg",
				"weapon_smg",
				"weapon_smg_silenced"
				};
				
				new bool:is_t2 = true;
				
				for(new i = 0; i < sizeof(t1_weapons); i++)
					if(StrContains(EdictName, t1_weapons[i], false) != -1)
						is_t2 = false;
				
				if(is_t2)
					AcceptEntityInput(Weapon, "Kill");
			}
		}
	}
	
	return Plugin_Handled;
}
public Action:HardCore_Mode_BW_Patch(Handle:event, const String:name[], bool:dontBroadcast)
{
	//if mode = any, b&w on incap is in effect
	if(GetConVarInt(HardCore_Mode) >= 1)
	{
		if(!GetEventBool(event, "ledge_hang"))
		{
			new Client = GetClientOfUserId(GetEventInt(event, "subject"))
			SetEntProp(Client, Prop_Send, "m_currentReviveCount", GetConVarInt(FindConVar("survivor_max_incapacitated_count")))	
			SetEntProp(Client, Prop_Send, "m_isGoingToDie", 1)
		}
	}
}
public Action:HardCore_Mode_Witch_Patch(Handle:event, const String:name[], bool:dontBroadcast)
{
	//if mode = any, hardcore witch is in effect...
	if(GetConVarInt(HardCore_Mode) >= 1)
	{
		decl Type;
		Type = GetEventInt(event, "type");
		
		if(Type == 4)
		{
			decl Client;
			Client = GetClientOfUserId(GetEventInt(event, "userid"));
			
			ForcePlayerSuicide(Client);
		}
	}
}
public Action:HardCore_Mode_Tank_Patch(Handle:event, const String:name[], bool:dontBroadcast)
{
	//if mode = any, hardcore tank is in effect...
	if(GetConVarInt(HardCore_Mode) >= 1)
	{
		new Tank = GetEventInt(event, "tankid");
		
		new Float:_Tank_Health = /*GetEntProp(Tank, Prop_Send, "m_iMaxHealth") * 1.5*/GetConVarInt(FindConVar("z_tank_health")) * 2.0;
		
		new Tank_Health = RoundToNearest(_Tank_Health);
		
		SetEntProp(Tank, Prop_Send, "m_iHealth", Tank_Health);
		SetEntProp(Tank, Prop_Send, "m_iMaxHealth", Tank_Health);
		//SetConVarInt(FindConVar("versus_tank_bonus_health"), Tank_Health);
	}
}

/*mode 4?
for(new i = 1; i <= MaxClients; i++)
{
	ClientCommand(client, "hidehud %i", 64 | 256);
	ClientCommand(client, "cl_glow_brightness 0", 64 | 256);
}
///////
if(has_died[character])
	ForcPlayerSuicide(client);
*/