#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

// #define CHAT_TAG "[BlockBuilder] "
//#define MESS "[BlockBuilder] %s"

new currentEnt[MAXPLAYERS+1];
new byUnits[MAXPLAYERS+1];
new Unit_Rotation[MAXPLAYERS+1] = false

enum BlockConfig
{
	String:BlockName[64],
	String:ModelPath[256],
	String:SoundPath[256],
	Float:EffectTime,
	Float:CooldownTime
}

#define     HEGrenadeOffset        14    // (14 * 4)
#define     FlashbangOffset        15    // (15 * 4)
#define     SmokegrenadeOffset        16    // (16 * 4)
#define     IncenderyGrenadesOffset    17    // (17 * 4) Also Molotovs
#define     DecoyGrenadeOffset        18    // (18 * 4)

new const String:INVI_SOUND_PATH[] = "*blockbuilder/invincibility.mp3"
new const String:STEALTH_SOUND_PATH[] = "*blockbuilder/stealth.mp3"
new const String:NUKE_SOUND_PATH[] = "*blockbuilder/nuke.mp3"
new const String:BOS_SOUND_PATH[] = "*blockbuilder/bootsofspeed.mp3"
new const String:CAM_SOUND_PATH[] = "*blockbuilder/camouflage.mp3"
new const String:TELE_SOUND_PATH[] = "*blockbuilder/teleport.mp3"

//new DuckHop[MAXPLAYERS+1] = false;
//new DuckHop_Perform[MAXPLAYERS+1] = false;
//new Float:DuckHop_Velocity[MAXPLAYERS+1][3]

new g_iDragEnt[MAXPLAYERS+1];
new g_iBlockSelection[MAXPLAYERS+1]={0, ...};
new g_iBlocks[2048] = {-1, ...};
new g_iTeleporters[2048] = {-1, ...};
// new g_iClientBlocks[MAXPLAYERS+1] = {-1, ...};
new g_iGravity[MAXPLAYERS+1]={0,...};
new g_iAmmo;
new g_iPrimaryAmmoType;
new g_iCurrentTele[MAXPLAYERS+1]={-1,...};
new g_iBeamSprite = 0;
new CurrentModifier[MAXPLAYERS+1] = 0
new Float:TrampolineForce[2048] = 0.0
new Float:SpeedBoostForce_1[2048] = 0.0
new Float:SpeedBoostForce_2[2048] = 0.0
//new Float:velocity_duck = 0.0
new Block_Transparency[2048] = 0

new bool:g_bNoFallDmg[MAXPLAYERS+1]={false,...};
new bool:g_bInvCanUse[MAXPLAYERS+1]={true,...};
new bool:g_bInv[MAXPLAYERS+1]={false,...};
new bool:g_bStealthCanUse[MAXPLAYERS+1]={true,...};
new bool:g_bBootsCanUse[MAXPLAYERS+1]={true,...};
new bool:g_bLocked[MAXPLAYERS+1]={false,...};
new bool:g_bTriggered[2048] = {false, ...};
new bool:g_bCamCanUse[MAXPLAYERS+1]={true,...};
new bool:g_bDeagleCanUse[MAXPLAYERS+1]={true,...}; 
new bool:g_bAwpCanUse[MAXPLAYERS+1]={true,...};
new bool:g_bHEgrenadeCanUse[MAXPLAYERS+1]={true,...};
new bool:g_bFlashbangCanUse[MAXPLAYERS+1]={true,...};
new bool:g_bSmokegrenadeCanUse[MAXPLAYERS+1]={true,...};
new bool:g_bSnapping[MAXPLAYERS+1]={false,...};
new bool:g_bGroups[MAXPLAYERS+1][2048];
new bool:g_bRandomCantUse[MAXPLAYERS+1]

new Handle:Block_Timers
new Block_Touching[MAXPLAYERS+1] = 0;


new Float:g_fSnappingGap[MAXPLAYERS+1]={0.0,...};
new Float:g_fClientAngles[MAXPLAYERS+1][3];
new Float:g_fAngles[2048][3];
new g_eBlocks[29][BlockConfig]; 

new Handle:g_hClientMenu[MAXPLAYERS+1];
new Handle:g_hBlocksKV = INVALID_HANDLE;
new Handle:g_hTeleSound = INVALID_HANDLE;

new Handle:Cvar_Prefix;
new Handle:Cvar_Height;
new Handle:Cvar_RandomTime;
new Float:TrueForce
new Float:randomblock_time = 0.0;
new String:CHAT_TAG[64];

new RoundIndex = 0; // Quite lazy way yet effective one

public Plugin:myinfo =
{
	name = "Blockmaker",
	author = "",
	description = "Blockmaker",
	version = "",
	url = ""
}

/* Changlog

1.0 - Initial Release
1.01:
 - Fixed occassional reset of transparency on some of blocks
 - Fixed Honey Block resetting if placed next to other block
1.02:
- Made Blockbuilder's messages white colored and prefix purple
- Added cvar sm_blockbuilder_prefix for changing Plugin Prefix as requested.
- Updated some of command names to support using them from chat
- Fixed desychronized effect time values due to using hardcoded ones rather the ones from config
- Fixed bug which caused Anti-CT & Anti-T blocks to be solid to players from their own teams...
1.03:
- Added Block Properties to Bunnyhop - No Slowdown Block
- Bunnyhop, delay, Bunnyhop No Slowdown can now be used from any directions and not just up...
- Managed to fix major issue which was getting stuck in blocks like bunnyhop, delayed and such after they re-appeared
1.04:
- Random Block is now usable, enjoy!
- Added Cvar 'sm_blockbuilder_random_cooldown' which decides cooldown between random block uses for each player.
- Rewritten the way Honey, Fire and Heal Blocks work.
- Nerfed Boots Of Speed velocity.
- Fixed another slowdown issue with honey block, hopefully last one.
- Removed unintentional leftover part of code which made plugin execute cvars from config. Now you can use server.cfg for your desired changes
1.041:
- Fixed Death Block Not Killing Players 
1.042:
- Added +grab and -grab and tgrab commands for picking up blocks... Thanks to Kwelje
- Added extra confirmation menu before saving/loading blocks
- Mr. Death Block's wild ride never ends. Another fix which fixes all issues with the block... Once more thanks to Kwelje
- Touching death block from any side will result in player's death now
1.043:
- Fixed issue with +grab not working
- Added command for direct save (sm_bsave)
- Added external autosave plugin function
- Added console messages for saving blocks
- Fixed stealth bug where players had infinite stealth
- Added function that remove all breakables
- Replaced smoke blocks with decoy blocks since they are frostnades in csgo
- Fixed so that you only receive 1 bullet from weapon blocks
- Changed deathblocks to only work from the top (Still needs some work)
 
*/
 
//public Action:Command_velocity_duck(client, args)
//{
//	decl String:argc[18]
//	GetCmdArg(1, argc, sizeof(argc))
	
//	velocity_duck = StringToFloat(argc)
//}


public OnPluginStart()
{

//	new pieces[4];
//	new longip = GetConVarInt(FindConVar("hostip"));
//	
//	pieces[0] = (longip >> 24) & 0x000000FF;
//	pieces[1] = (longip >> 16) & 0x000000FF;
//	pieces[2] = (longip >> 8) & 0x000000FF;
//	pieces[3] = longip & 0x000000FF;
//
//	decl String:NetIP[32]
//	Format(NetIP, sizeof(NetIP), "%d.%d.%d.%d", pieces[0], pieces[1], pieces[2], pieces[3]);
//	if(StrEqual(NetIP, "255.255.255.255"))
//	{
	randomblock_time = 60.0;
	g_hTeleSound = CreateConVar("sm_blockbuilder_telesound", "blockbuilder/teleport.mp3");
	Cvar_Height = CreateConVar("sm_blockbuilder_block_height",	"0.0", "Height of block (Can be -10.0 aswell as 15.0")
	HookConVarChange(Cvar_Height, OnHeightConVarChange)

	Format(CHAT_TAG, sizeof(CHAT_TAG), "[BM]")
	Cvar_Prefix = CreateConVar("sm_blockbuilder_prefix",	"[BM]", "A Prefix used by messages within Blockbuilder...")
	HookConVarChange(Cvar_Prefix, OnPrefixChanged)
	
	Cvar_RandomTime = CreateConVar("sm_blockbuilder_random_cooldown", "60", "A cooldown for using random block for player. Example: After you use once random block you need to wait 60 sec.")
	HookConVarChange(Cvar_RandomTime, OnRandomChanged)

	//
	//    ADMIN FLAG "O" FOR USING BLOCKMAKER
	//    ADMIN FLAG "P" FOR SAVING AND LOADING
	//
	
//	RegConsoleCmd("sm_bb", Command_BlockBuilder);
	RegAdminCmd("sm_bb", Command_BlockBuilder, ADMFLAG_CUSTOM1);
//	RegConsoleCmd("sm_bsave", Command_SaveBlocks);
	RegAdminCmd("sm_bsave", Command_SaveBlocks, ADMFLAG_CUSTOM2);
	RegAdminCmd("sm_unitmover", Command_UnitMove, ADMFLAG_CUSTOM1);
	RegAdminCmd("sm_blocksnap", Command_BlockSnap, ADMFLAG_CUSTOM1);
	RegAdminCmd("sm_snapgrid", Command_SnapGrid, ADMFLAG_CUSTOM1);
	RegAdminCmd("+grab", Command_GrabBlock, ADMFLAG_CUSTOM1);
	RegAdminCmd("-grab", Command_ReleaseBlock, ADMFLAG_CUSTOM1);
	RegAdminCmd("tgrab", Command_ToggleGrab, ADMFLAG_CUSTOM1);
//	RegAdminCmd("velocity_duck", Command_velocity_duck, ADMFLAG_CUSTOM1);
	
	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);
	
	AutoExecConfig();
	
	g_iAmmo = FindSendPropOffs("CCSPlayer", "m_iAmmo");
	g_iPrimaryAmmoType = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoType");
	
	new String:file[256];
	BuildPath(Path_SM, file, sizeof(file), "configs/blockbuilder.blocks.txt");
	
	new Handle:kv = CreateKeyValues("Blocks");
	FileToKeyValues(kv, file);
	
	if (!KvGotoFirstSubKey(kv))
	{
		PrintToServer("No first subkey");
		return;
	}
	
	new i = 0;
	
	do
	{		
		KvGetSectionName(kv, g_eBlocks[i][BlockName], 64);
		KvGetString(kv, "model", g_eBlocks[i][ModelPath], 256);
		KvGetString(kv, "sound", g_eBlocks[i][SoundPath], 256);
		g_eBlocks[i][EffectTime] = KvGetFloat(kv, "effect");
		g_eBlocks[i][CooldownTime] = KvGetFloat(kv, "cooldown");
		++i;
	} while (KvGotoNextKey(kv));
	
	CloseHandle(kv);
	
	g_hBlocksKV = CreateKeyValues("Blocks");
}

public Action:Command_GrabBlock(client, args)
{
	if(g_iDragEnt[client] == 0)
	{
		new ent = GetClientAimTarget(client, false);
		if(IsValidBlock(ent))
		{
			g_iDragEnt[client] = ent;
			if(g_bGroups[client][g_iDragEnt[client]])
			{
				for(new i=0;i<2048;++i)
				{
					if(IsValidBlock(i) && g_bGroups[client][i])
					{
						SetEntityMoveType(i, MOVETYPE_VPHYSICS);
						AcceptEntityInput(i, "enablemotion");
					}
				}
			}
			else
			{
				SetEntityMoveType(g_iDragEnt[client], MOVETYPE_VPHYSICS);
				AcceptEntityInput(g_iDragEnt[client], "enablemotion");
			}
			//PrintToChat(client, MESS, "Block has been grabbed.");
		}
		else
		{
	//		CreateBlock(client);
		}
	}
}

public Action:Command_ReleaseBlock(client, args)
{
	if(g_iDragEnt[client] != 0)
	{
		new Float:fVelocity[3] = {0.0, 0.0, 0.0};
		TeleportEntity(g_iDragEnt[client], NULL_VECTOR, g_fAngles[g_iDragEnt[client]], fVelocity);
		if(g_bGroups[client][g_iDragEnt[client]])
		{
			for(new i=0;i<2048;++i)
			{
				if(IsValidBlock(i) && g_bGroups[client][i])
				{
					SetEntityMoveType(i, MOVETYPE_NONE);
					AcceptEntityInput(i, "disablemotion");
				}
			}
		}
		else
		{
			SetEntityMoveType(g_iDragEnt[client], MOVETYPE_NONE);
			AcceptEntityInput(g_iDragEnt[client], "disablemotion");
		}
		g_iDragEnt[client] = 0;
		//PrintToChat(client, MESS, "Block has been released.");
	}
}

public Action:Command_ToggleGrab(client, args)
{
	if(g_iDragEnt[client] != 0)
	{
		new Float:fVelocity[3] = {0.0, 0.0, 0.0};
		TeleportEntity(g_iDragEnt[client], NULL_VECTOR, g_fAngles[g_iDragEnt[client]], fVelocity);
		if(g_bGroups[client][g_iDragEnt[client]])
		{
			for(new i=0;i<2048;++i)
			{
				if(IsValidBlock(i) && g_bGroups[client][i])
				{
					SetEntityMoveType(i, MOVETYPE_NONE);
					AcceptEntityInput(i, "disablemotion");
				}
			}
		}
		else
		{
			SetEntityMoveType(g_iDragEnt[client], MOVETYPE_NONE);
			AcceptEntityInput(g_iDragEnt[client], "disablemotion");
		}
		g_iDragEnt[client] = 0;
		//PrintToChat(client, MESS, "Block has been released.");
	}
	else
	{
		new ent = GetClientAimTarget(client, false);
		if(IsValidBlock(ent))
		{
			g_iDragEnt[client] = ent;
			if(g_bGroups[client][g_iDragEnt[client]])
			{
				for(new i=0;i<2048;++i)
				{
					if(IsValidBlock(i) && g_bGroups[client][i])
					{
						SetEntityMoveType(i, MOVETYPE_VPHYSICS);
						AcceptEntityInput(i, "enablemotion");
					}
				}
			}
			else
			{
				SetEntityMoveType(g_iDragEnt[client], MOVETYPE_VPHYSICS);
				AcceptEntityInput(g_iDragEnt[client], "enablemotion");
			}
			//PrintToChat(client, MESS, "Block has been grabbed.");
		}
		else
		{
		//	CreateBlock(client);
		}
	}
}

public OnRandomChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	randomblock_time = StringToFloat(newVal)
}

public OnPrefixChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	Format(CHAT_TAG, sizeof(CHAT_TAG), "%s", newVal)
}

public Action:Command_BlockSnap(client, args)
{
	if(g_bSnapping[client])
	{
		g_bSnapping[client] = false
		PrintToChat(client, "\x03%s\x04 Block Snapping Off.", CHAT_TAG);
	}
	else
	{
		PrintToChat(client, "\x03%s\x04 Block Snapping On.", CHAT_TAG);
		g_bSnapping[client] = true;
	}
}

public Action:Command_SnapGrid(client, args)
{
	decl String:argc[18]
	GetCmdArg(1, argc, sizeof(argc))
	
	g_fSnappingGap[client] = StringToFloat(argc)
}

public Action:Command_UnitMove(client, args)
{
	decl Float:vecAngles[3], Float:vecOrigin[3];
	GetClientEyePosition(client, vecOrigin);
	GetClientEyeAngles(client, vecAngles);
	
	new entity = GetClientAimTarget(client, false);
	if(IsValidBlock(entity) || g_iTeleporters[entity])
	{
		currentEnt[client] = entity
		DrawUnitMovePanel(client);
		return Plugin_Handled;
	}
	PrintToChat(client, "\x03%s\x04 You have to aim at the object to change it's position.", CHAT_TAG);
	DisplayMenu(CreateMainMenu(client), client, 0);
	
	return Plugin_Handled;
}

DrawUnitMovePanel(client)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Advanced Block Placement");
	decl String:concatedMoveBy[128];
	Format(concatedMoveBy, sizeof(concatedMoveBy), "%s%f", "Move by: ", float(byUnits[client]) / 10);
	DrawPanelItem(panel, concatedMoveBy);
	DrawPanelItem(panel, "X+");
	DrawPanelItem(panel, "X-");
	DrawPanelItem(panel, "Y+");
	DrawPanelItem(panel, "Y-");
	DrawPanelItem(panel, "Z+");
	DrawPanelItem(panel, "Z-");
	if(!Unit_Rotation[client])
	{
		DrawPanelItem(panel, "Mode: Position");
	}
	else
	{
		DrawPanelItem(panel, "Mode: Rotation");
	}
	DrawPanelItem(panel, "Exit");
	SendPanelToClient(panel, client, DrawUnitMovePanelHandler, 360);
 
	CloseHandle(panel);
}
/*
 DETOUR_DECL_STATIC5(KillEater, void*, void *, item, CBaseEntity *, attacker, CBaseEntity *, victim, struct kill_eater_event_t, data, int, unk5)
{
if (victim == 0)
return DETOUR_STATIC_CALL(KillEater)(item, attacker, victim, data, unk5);
*/

public DrawUnitMovePanelHandler(Handle:menu, MenuAction:action, client, key)
{
	if (action == MenuAction_Select)
	{
		new Float:currentEntLocation[3];
		if(!Unit_Rotation[client])
		{
			GetEntPropVector(currentEnt[client], Prop_Send, "m_vecOrigin", currentEntLocation);
		}
		else
		{
			GetEntPropVector(currentEnt[client], Prop_Data, "m_angRotation", currentEntLocation);  
		}
		
		new Float:byUnitsFloat = float(byUnits[client]) / 10;
		new Dont = false
		switch(key) 
		{
			case 1: 
			{
				switch(byUnits[client]) 
				{
					case 1: 
					{
						byUnits[client] = 5;
					}
					case 5: 
					{
						byUnits[client] = 10;
					}
					case 10: 
					{
						byUnits[client] = 80;
					}
					case 120: 
					{
						byUnits[client] = 320;
					}
					case 330: 
					{
						byUnits[client] = 640;
					}
					case 660: 
					{
						byUnits[client] = 1;
					}
					default: 
					{
						byUnits[client] = 1;
					}
				}
			}
			case 2: 
			{ 
				currentEntLocation[0] += byUnitsFloat;
			}
			case 3: 
			{ 
				currentEntLocation[0] -= byUnitsFloat;
			}
			case 4: 
			{ 
				currentEntLocation[1] += byUnitsFloat;
			}
			case 5: 
			{ 
				currentEntLocation[1] -= byUnitsFloat;
			}
			case 6: 
			{ 
				currentEntLocation[2] += byUnitsFloat;
			}
			case 7: 
			{ 
				currentEntLocation[2] -= byUnitsFloat;
			}
			case 8:
			{
					if(!Unit_Rotation[client])
					{
						Unit_Rotation[client] = true;
					}
					else
					{
						Unit_Rotation[client] = false;
					}
			}
			case 9: 
			{ 
				CreateMainMenu(client);
				Dont = true
			}
		}
		if(!Dont)
			DrawUnitMovePanel(client);
		if(!(key == 8))
		{
			if(!Unit_Rotation[client])
			{
				TeleportEntity(currentEnt[client], currentEntLocation, NULL_VECTOR, NULL_VECTOR);
			}
			else
			{
				TeleportEntity(currentEnt[client], NULL_VECTOR, currentEntLocation, NULL_VECTOR);
			}
		}
	}
}

public OnHeightConVarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	TrueForce = StringToFloat(newVal)
}

// REMOVE BREAKABLES
public OnEntityCreated(entity, const String:classname[]) {  
    if(StrEqual(classname, "func_breakable") || StrEqual(classname, "func_breakable_surf")) { 
        SDKHook(entity, SDKHook_Spawn, Hook_OnEntitySpawn);  
    }  
}  
public Action:Hook_OnEntitySpawn(entity) {  
    AcceptEntityInput(entity, "Kill");  
    return Plugin_Handled;  
} 
// END OF REMOVE BREAKABLES

public OnConfigsExecuted()
{
	new String:sound[512];
	GetConVarString(g_hTeleSound, sound, sizeof(sound));
	if(!StrEqual(sound, ""))
	{
		PrecacheSound(sound);
	}
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// STEALTH FIX ?? 
	for(int client = 1; client <= MaxClients; client++) 
    { 
        if(!IsClientInGame(client)) 
            continue;
        SetEntityRenderMode(client , RENDER_NORMAL); 
		SDKUnhook(client, SDKHook_SetTransmit, Stealth_SetTransmit)
    } 

	for(new i=0;i<2048;++i)
	{
		g_iBlocks[i]=-1;
		g_bTriggered[i]=false;
		g_iTeleporters[i]=-1;
	}
	for(new i=1;i<=MaxClients;++i)
	{
		g_bHEgrenadeCanUse[i]=true;
		g_bFlashbangCanUse[i]=true;
		g_bSmokegrenadeCanUse[i]=true;
		g_iCurrentTele[i]=-1;
		g_bInv[i]=false;
		g_bInvCanUse[i]=true;
		g_bStealthCanUse[i]=true;
		g_bBootsCanUse[i]=true;
		g_bLocked[i]=false;
		g_bNoFallDmg[i]=false;
		g_bCamCanUse[i]=true;
		g_bAwpCanUse[i]=true;
		g_bDeagleCanUse[i]=true;
		g_bRandomCantUse[i]=false;
	}
	RoundIndex++
	LoadBlocks();
	return Plugin_Continue;
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	g_bInv[client]=false;
	g_bInvCanUse[client]=true;
	g_bStealthCanUse[client]=true;
	g_bBootsCanUse[client]=true;
	g_bLocked[client]=false;
	g_bNoFallDmg[client]=false;
	g_bCamCanUse[client]=true;
	g_bAwpCanUse[client]=true;
	g_bDeagleCanUse[client]=true;
	g_bHEgrenadeCanUse[client]=true;
	g_bFlashbangCanUse[client]=true;
//	g_iClientBlocks[client]=-1;
	g_iCurrentTele[client]=-1;
	g_bSnapping[client] = false;
	g_bRandomCantUse[client] = false;
	g_fSnappingGap[client] = 0.0
	for(new i=0;i<2048;++i)
		g_bGroups[client][i]=false;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnMapStart()
{
	RoundIndex = 0;
	SetConVarBool(FindConVar("sv_turbophysics"), true);

	for(new i=0;i<sizeof(g_eBlocks);++i)
	{
		if(strcmp(g_eBlocks[i][SoundPath], "")!=0)
			PrecacheSound(g_eBlocks[i][SoundPath], true);
	}
	
	PrecacheModel("models/blockbuilder/tele_start.mdl", true);
	PrecacheModel("models/blockbuilder/tele_end.mdl", true);
	PrecacheModel("models/player/ctm_gign.mdl");
	PrecacheModel("models/player/tm_phoenix.mdl");
	
	FakePrecacheSound(INVI_SOUND_PATH);
	FakePrecacheSound(STEALTH_SOUND_PATH);
	FakePrecacheSound(NUKE_SOUND_PATH);
	FakePrecacheSound(BOS_SOUND_PATH);
	FakePrecacheSound(CAM_SOUND_PATH);
	FakePrecacheSound(TELE_SOUND_PATH);

	DownloadsTable()
	
	g_iBeamSprite = PrecacheModel("materials/sprites/orangelight1.vmt");
	
	for(new i=0;i<2048;++i)
	{
		for(new a=1;a<=MaxClients;++a)
		{
			g_bGroups[a][i]=false;
		}
		g_iBlocks[i]=-1;
		g_iTeleporters[i]=-1;
		g_bTriggered[i]=false;
	}
	
	if(g_hBlocksKV != INVALID_HANDLE)
	{
		CloseHandle(g_hBlocksKV);
		g_hBlocksKV = INVALID_HANDLE;
	}
		
	new String:file[256];
	new String:map[64];
	//new String:id[64];
	//GetCurrentWorkshopMap(map, 65, id, 65)
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, file, sizeof(file), "data/block.%s.txt", map);
	if(FileExists(file))
	{
		g_hBlocksKV = CreateKeyValues("Blocks");
		FileToKeyValues(g_hBlocksKV, file);
	}
}

DownloadsTable()
{
	PrecacheModel("models/blockbuilder/awp.mdl")
	PrecacheModel("models/blockbuilder/bhop.mdl")
	PrecacheModel("models/blockbuilder/camouflage.mdl")
	PrecacheModel("models/blockbuilder/ctbarrier.mdl")
	PrecacheModel("models/blockbuilder/damage.mdl")
	PrecacheModel("models/blockbuilder/deagle.mdl")
	PrecacheModel("models/blockbuilder/death.mdl")
	PrecacheModel("models/blockbuilder/delay.mdl")
	PrecacheModel("models/blockbuilder/fire.mdl")
	PrecacheModel("models/blockbuilder/flash.mdl")
	PrecacheModel("models/blockbuilder/frost.mdl")
	PrecacheModel("models/blockbuilder/glass.mdl")
	PrecacheModel("models/blockbuilder/gravity.mdl")
	PrecacheModel("models/blockbuilder/he.mdl")
	PrecacheModel("models/blockbuilder/health.mdl")
	PrecacheModel("models/blockbuilder/honey.mdl")
	PrecacheModel("models/blockbuilder/ice.mdl")
	PrecacheModel("models/blockbuilder/invincibility.mdl")
	PrecacheModel("models/blockbuilder/nofalldmg.mdl")
	PrecacheModel("models/blockbuilder/noslowdown.mdl")
	PrecacheModel("models/blockbuilder/nuke.mdl")
	PrecacheModel("models/blockbuilder/platform.mdl")
	PrecacheModel("models/blockbuilder/random.mdl")
	PrecacheModel("models/blockbuilder/slap.mdl")
	PrecacheModel("models/blockbuilder/speed.mdl")
	PrecacheModel("models/blockbuilder/speedboost.mdl")
	PrecacheModel("models/blockbuilder/stealth.mdl")
	PrecacheModel("models/blockbuilder/tbarrier.mdl")
	PrecacheModel("models/blockbuilder/tramp.mdl")
	
	AddFileToDownloadsTable("models/blockbuilder/tele_start.mdl");
	AddFileToDownloadsTable("models/blockbuilder/tele_start.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/tele_start.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/tele_start.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/tele_start.phy")
	AddFileToDownloadsTable("models/blockbuilder/tele_start.vvd")
	AddFileToDownloadsTable("models/blockbuilder/tele_end.mdl");
	AddFileToDownloadsTable("models/blockbuilder/tele_end.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/tele_end.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/tele_end.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/tele_end.phy")
	AddFileToDownloadsTable("models/blockbuilder/tele_end.vvd")
	
	AddFileToDownloadsTable("models/blockbuilder/awp.mdl")
	AddFileToDownloadsTable("models/blockbuilder/bhop.mdl")
	AddFileToDownloadsTable("models/blockbuilder/camouflage.mdl")
	AddFileToDownloadsTable("models/blockbuilder/ctbarrier.mdl")
	AddFileToDownloadsTable("models/blockbuilder/damage.mdl")
	AddFileToDownloadsTable("models/blockbuilder/deagle.mdl")
	AddFileToDownloadsTable("models/blockbuilder/death.mdl")
	AddFileToDownloadsTable("models/blockbuilder/delay.mdl")
	AddFileToDownloadsTable("models/blockbuilder/fire.mdl")
	AddFileToDownloadsTable("models/blockbuilder/flash.mdl")
	AddFileToDownloadsTable("models/blockbuilder/frost.mdl")
	AddFileToDownloadsTable("models/blockbuilder/glass.mdl")
	AddFileToDownloadsTable("models/blockbuilder/gravity.mdl")
	AddFileToDownloadsTable("models/blockbuilder/he.mdl")
	AddFileToDownloadsTable("models/blockbuilder/health.mdl")
	AddFileToDownloadsTable("models/blockbuilder/honey.mdl")
	AddFileToDownloadsTable("models/blockbuilder/ice.mdl")
	AddFileToDownloadsTable("models/blockbuilder/invincibility.mdl")
	AddFileToDownloadsTable("models/blockbuilder/nofalldmg.mdl")
	AddFileToDownloadsTable("models/blockbuilder/noslowdown.mdl")
	AddFileToDownloadsTable("models/blockbuilder/nuke.mdl")
	AddFileToDownloadsTable("models/blockbuilder/platform.mdl")
	AddFileToDownloadsTable("models/blockbuilder/random.mdl")
	AddFileToDownloadsTable("models/blockbuilder/slap.mdl")
	AddFileToDownloadsTable("models/blockbuilder/speed.mdl")
	AddFileToDownloadsTable("models/blockbuilder/speedboost.mdl")
	AddFileToDownloadsTable("models/blockbuilder/stealth.mdl")
	AddFileToDownloadsTable("models/blockbuilder/tbarrier.mdl")
	AddFileToDownloadsTable("models/blockbuilder/tramp.mdl")
	
	AddFileToDownloadsTable("models/blockbuilder/awp.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/bhop.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/camouflage.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/ctbarrier.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/damage.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/deagle.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/death.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/delay.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/fire.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/flash.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/frost.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/glass.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/gravity.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/he.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/health.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/honey.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/ice.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/invincibility.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/nofalldmg.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/noslowdown.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/nuke.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/platform.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/random.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/slap.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/speed.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/speedboost.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/stealth.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/tbarrier.dx80.vtx")
	AddFileToDownloadsTable("models/blockbuilder/tramp.dx80.vtx")
	
	AddFileToDownloadsTable("models/blockbuilder/awp.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/bhop.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/camouflage.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/ctbarrier.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/damage.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/deagle.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/death.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/delay.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/fire.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/flash.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/frost.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/glass.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/gravity.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/he.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/health.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/honey.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/ice.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/invincibility.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/nofalldmg.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/noslowdown.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/nuke.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/platform.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/random.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/slap.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/speed.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/speedboost.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/stealth.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/tbarrier.dx90.vtx")
	AddFileToDownloadsTable("models/blockbuilder/tramp.dx90.vtx")
	
	AddFileToDownloadsTable("models/blockbuilder/awp.phy")
	AddFileToDownloadsTable("models/blockbuilder/bhop.phy")
	AddFileToDownloadsTable("models/blockbuilder/camouflage.phy")
	AddFileToDownloadsTable("models/blockbuilder/ctbarrier.phy")
	AddFileToDownloadsTable("models/blockbuilder/damage.phy")
	AddFileToDownloadsTable("models/blockbuilder/deagle.phy")
	AddFileToDownloadsTable("models/blockbuilder/death.phy")
	AddFileToDownloadsTable("models/blockbuilder/delay.phy")
	AddFileToDownloadsTable("models/blockbuilder/fire.phy")
	AddFileToDownloadsTable("models/blockbuilder/flash.phy")
	AddFileToDownloadsTable("models/blockbuilder/frost.phy")
	AddFileToDownloadsTable("models/blockbuilder/glass.phy")
	AddFileToDownloadsTable("models/blockbuilder/gravity.phy")
	AddFileToDownloadsTable("models/blockbuilder/he.phy")
	AddFileToDownloadsTable("models/blockbuilder/health.phy")
	AddFileToDownloadsTable("models/blockbuilder/honey.phy")
	AddFileToDownloadsTable("models/blockbuilder/ice.phy")
	AddFileToDownloadsTable("models/blockbuilder/invincibility.phy")
	AddFileToDownloadsTable("models/blockbuilder/nofalldmg.phy")
	AddFileToDownloadsTable("models/blockbuilder/noslowdown.phy")
	AddFileToDownloadsTable("models/blockbuilder/nuke.phy")
	AddFileToDownloadsTable("models/blockbuilder/platform.phy")
	AddFileToDownloadsTable("models/blockbuilder/random.phy")
	AddFileToDownloadsTable("models/blockbuilder/slap.phy")
	AddFileToDownloadsTable("models/blockbuilder/speed.phy")
	AddFileToDownloadsTable("models/blockbuilder/speedboost.phy")
	AddFileToDownloadsTable("models/blockbuilder/stealth.phy")
	AddFileToDownloadsTable("models/blockbuilder/tbarrier.phy")
	AddFileToDownloadsTable("models/blockbuilder/tramp.phy")
	
	AddFileToDownloadsTable("models/blockbuilder/awp.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/bhop.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/camouflage.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/ctbarrier.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/damage.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/deagle.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/death.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/delay.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/fire.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/flash.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/frost.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/glass.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/gravity.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/he.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/health.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/honey.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/ice.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/invincibility.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/nofalldmg.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/noslowdown.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/nuke.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/platform.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/random.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/slap.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/speed.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/speedboost.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/stealth.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/tbarrier.sw.vtx")
	AddFileToDownloadsTable("models/blockbuilder/tramp.sw.vtx")

	AddFileToDownloadsTable("models/blockbuilder/awp.vvd")
	AddFileToDownloadsTable("models/blockbuilder/bhop.vvd")
	AddFileToDownloadsTable("models/blockbuilder/camouflage.vvd")
	AddFileToDownloadsTable("models/blockbuilder/ctbarrier.vvd")
	AddFileToDownloadsTable("models/blockbuilder/damage.vvd")
	AddFileToDownloadsTable("models/blockbuilder/deagle.vvd")
	AddFileToDownloadsTable("models/blockbuilder/death.vvd")
	AddFileToDownloadsTable("models/blockbuilder/delay.vvd")
	AddFileToDownloadsTable("models/blockbuilder/fire.vvd")
	AddFileToDownloadsTable("models/blockbuilder/flash.vvd")
	AddFileToDownloadsTable("models/blockbuilder/frost.vvd")
	AddFileToDownloadsTable("models/blockbuilder/glass.vvd")
	AddFileToDownloadsTable("models/blockbuilder/gravity.vvd")
	AddFileToDownloadsTable("models/blockbuilder/he.vvd")
	AddFileToDownloadsTable("models/blockbuilder/health.vvd")
	AddFileToDownloadsTable("models/blockbuilder/honey.vvd")
	AddFileToDownloadsTable("models/blockbuilder/ice.vvd")
	AddFileToDownloadsTable("models/blockbuilder/invincibility.vvd")
	AddFileToDownloadsTable("models/blockbuilder/nofalldmg.vvd")
	AddFileToDownloadsTable("models/blockbuilder/noslowdown.vvd")
	AddFileToDownloadsTable("models/blockbuilder/nuke.vvd")
	AddFileToDownloadsTable("models/blockbuilder/platform.vvd")
	AddFileToDownloadsTable("models/blockbuilder/random.vvd")
	AddFileToDownloadsTable("models/blockbuilder/slap.vvd")
	AddFileToDownloadsTable("models/blockbuilder/speed.vvd")
	AddFileToDownloadsTable("models/blockbuilder/speedboost.vvd")
	AddFileToDownloadsTable("models/blockbuilder/stealth.vvd")
	AddFileToDownloadsTable("models/blockbuilder/tbarrier.vvd")
	AddFileToDownloadsTable("models/blockbuilder/tramp.vvd")
	
	 
	AddFileToDownloadsTable("materials/models/blockbuilder/glow2.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/glow2.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/awp.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/awp.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/awp_side.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/awp_side.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/bhop.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/bhop.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/bhop_side.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/bhop_side.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/tele_start.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/tele_start.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/camouflage.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/camouflage.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/camouflage_side.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/camouflage_side.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/ctbarrier.vmt") 
	AddFileToDownloadsTable("materials/models/blockbuilder/ctbarrier.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/ctbarrier_side.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/ctbarrier_side.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/damage.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/damage.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/damage_side.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/damage_side.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/deagle.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/deagle.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/deagle_side.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/deagle_side.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/death.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/death.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/death_n.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/delay.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/delay.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/delay_side.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/delay_side.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/fire.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/fire.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/fire_side.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/fire_side.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/flash.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/flash.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/frost.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/frost.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/frost_side.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/frost_side.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/glass.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/glass.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/gravity.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/gravity.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/gravity_side.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/gravity_side.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/he.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/he.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/he_side.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/he_side.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/health.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/health.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/health_n.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/honey.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/honey.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/honey_side.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/honey_side.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/ice_n.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/invincibility.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/invincibility.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/invincibility_side.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/invincibility_side.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/nofalldmg.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/nofalldmg.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/nofalldmg_side.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/nofalldmg_side.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/noslowdown.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/noslowdown.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/noslowdown_side.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/noslowdown_side.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/nuke.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/nuke.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/platform.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/platform.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/platform_side.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/platform_side.vtf") 
	AddFileToDownloadsTable("materials/models/blockbuilder/random.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/random.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/random_side.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/random_side.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/tele_end.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/tele_end.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/slap.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/slap.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/speed.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/speed.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/speed_n.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/speedboost.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/speedboost.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/sphere.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/sphere.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/stealth.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/stealth.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/stealth_side.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/stealth_side.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/tape.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/tape.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/tbarrier.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/tbarrier.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/tbarrier_side.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/tbarrier_side.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/tramp.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/tramp.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/tramp_n.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/ice_top.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/ice_top.vtf")
}

public Action:Command_SaveBlocks(client, args)
{

	if(client)
	{
//		if(!(GetUserFlagBits(client) & ADMFLAG_CUSTOM1 || GetUserFlagBits(client) & ADMFLAG_ROOT))
//		{
//			PrintToChat(client, "\x03%s\x04 You don't have permission to access this.", CHAT_TAG);
//			return Plugin_Handled;
//		}
	}
	else {
		new iPlayers = 0;
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				iPlayers++;
			}
		}
		if(!iPlayers)
		{
			PrintToServer("You can only save when at least one client is in-game");
			return Plugin_Handled;
		}
	}
	
	
	if(g_hBlocksKV != INVALID_HANDLE)
		CloseHandle(g_hBlocksKV);
	g_hBlocksKV = CreateKeyValues("Blocks");
	KvGotoFirstSubKey(g_hBlocksKV);
	new index = 1, blocks=0,teleporters=0;
	new String:tmp[11];
	new Float:fPos[3], Float:fAng[3];
	for(new i=0;i<2048;++i)
	{
		if(!IsValidBlock(i) || g_iTeleporters[i]==1)
			continue;
		
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", fPos);
		
	
		IntToString(index, tmp, sizeof(tmp));
		KvJumpToKey(g_hBlocksKV, tmp, true);
		if(g_iTeleporters[i]>1 && IsValidBlock(g_iTeleporters[i]))
		{
			GetEntPropVector(g_iTeleporters[i], Prop_Data, "m_vecOrigin", fAng);
			KvSetNum(g_hBlocksKV, "teleporter", 1);
			KvSetVector(g_hBlocksKV, "entrance", fPos);
			KvSetVector(g_hBlocksKV, "exit", fAng);
			teleporters++;
		}
		else
		{
			GetEntPropVector(i, Prop_Data, "m_angRotation", fAng);
			KvSetNum(g_hBlocksKV, "blocktype", g_iBlocks[i]);
			KvSetVector(g_hBlocksKV, "position", fPos);
			KvSetVector(g_hBlocksKV, "angles", fAng);
			if(g_iBlocks[i] == 5)
			{
				KvSetFloat(g_hBlocksKV, "attrib1", TrampolineForce[i])
			}
			else if(g_iBlocks[i] == 6)
			{
				KvSetFloat(g_hBlocksKV, "attrib1", SpeedBoostForce_1[i])
				KvSetFloat(g_hBlocksKV, "attrib2", SpeedBoostForce_2[i])
			}
			else if(g_iBlocks[i] == 28 || g_iBlocks[i] == 18 || g_iBlocks[i] == 1)
			{
				KvSetFloat(g_hBlocksKV, "attrib1", SpeedBoostForce_1[i])
			}
			if(Block_Transparency[i] > 0)
				KvSetNum(g_hBlocksKV, "transparency", Block_Transparency[i])
			blocks++;
		}
		KvGoBack(g_hBlocksKV);
		index++;
	}
	KvRewind(g_hBlocksKV);
	new String:file[256];
	new String:map[64];
	//new String:id[64];

	//GetCurrentWorkshopMap(map, 65, id, 65)
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, file, sizeof(file), "data/block.%s.txt", map);
	KeyValuesToFile(g_hBlocksKV, file);
	
	PrintToChatAll("\x03%s\x04 %d blocks and %d pair of teleporters were saved.", CHAT_TAG, blocks, teleporters);
	PrintToServer("%d blocks and %d teleports saved", blocks, teleporters);

	return Plugin_Handled;
}

SaveBlocks(bool:msg=false)
{
	if(g_hBlocksKV != INVALID_HANDLE)
		CloseHandle(g_hBlocksKV);
	g_hBlocksKV = CreateKeyValues("Blocks");
	KvGotoFirstSubKey(g_hBlocksKV);
	new index = 1, blocks=0,teleporters=0;
	new String:tmp[11];
	new Float:fPos[3], Float:fAng[3];
	for(new i=MaxClients+1;i<=2048;++i)
	{
		if(!IsValidBlock(i) || g_iTeleporters[i]==1)
			continue;
		
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", fPos);
		
	
		IntToString(index, tmp, sizeof(tmp));
		KvJumpToKey(g_hBlocksKV, tmp, true);
		if(g_iTeleporters[i]>1 && IsValidBlock(g_iTeleporters[i]))
		{
			GetEntPropVector(g_iTeleporters[i], Prop_Data, "m_vecOrigin", fAng);
			KvSetNum(g_hBlocksKV, "teleporter", 1);
			KvSetVector(g_hBlocksKV, "entrance", fPos);
			KvSetVector(g_hBlocksKV, "exit", fAng);
			teleporters++;
		}
		else
		{
			GetEntPropVector(i, Prop_Data, "m_angRotation", fAng);
			KvSetNum(g_hBlocksKV, "blocktype", g_iBlocks[i]);
			KvSetVector(g_hBlocksKV, "position", fPos);
			KvSetVector(g_hBlocksKV, "angles", fAng);
			if(g_iBlocks[i] == 5)
			{
				KvSetFloat(g_hBlocksKV, "attrib1", TrampolineForce[i])
			}
			else if(g_iBlocks[i] == 6)
			{
				KvSetFloat(g_hBlocksKV, "attrib1", SpeedBoostForce_1[i])
				KvSetFloat(g_hBlocksKV, "attrib2", SpeedBoostForce_2[i])
			}
			else if(g_iBlocks[i] == 28 || g_iBlocks[i] == 18 || g_iBlocks[i] == 1)
			{
				KvSetFloat(g_hBlocksKV, "attrib1", SpeedBoostForce_1[i])
			}
			if(Block_Transparency[i] > 0)
				KvSetNum(g_hBlocksKV, "transparency", Block_Transparency[i])
			blocks++;
		}
		KvGoBack(g_hBlocksKV);
		index++;
	}
	KvRewind(g_hBlocksKV);
	new String:file[256];
	new String:map[64];
	//new String:id[64];

	//GetCurrentWorkshopMap(map, 65, id, 65)
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, file, sizeof(file), "data/block.%s.txt", map);
	KeyValuesToFile(g_hBlocksKV, file);
	
	if(msg)
		PrintToChatAll("\x03%s\x04 %d blocks and %d pair of teleporters were saved.", CHAT_TAG, blocks, teleporters);
		PrintToServer("%d blocks and %d teleports saved", blocks, teleporters);
}

LoadBlocks(bool:msg=false)
{
	if(g_hBlocksKV == INVALID_HANDLE)
		return;
		
	new teleporters=0, blocks=0;
	new Float:fPos[3], Float:fAng[3];
	KvRewind(g_hBlocksKV);
	KvGotoFirstSubKey(g_hBlocksKV);
	do
	{
		if(KvGetNum(g_hBlocksKV, "teleporter") == 1)
		{
			KvGetVector(g_hBlocksKV, "entrance", fPos);
			KvGetVector(g_hBlocksKV, "exit", fAng);
			g_iTeleporters[CreateTeleportEntrance(0, fPos)] = CreateTeleportExit(0, fAng);
			teleporters++;
		}
		else
		{
			KvGetVector(g_hBlocksKV, "position", fPos);
			KvGetVector(g_hBlocksKV, "angles", fAng);
			new transparency = KvGetNum(g_hBlocksKV, "transparency", 0)
			new blocktype = KvGetNum(g_hBlocksKV, "blocktype")
			if(blocktype == 5)
			{
				CreateBlock(0, blocktype, fPos, fAng, KvGetFloat(g_hBlocksKV, "attrib1"), 0.0, transparency)
			}
			else if(blocktype == 6)
			{
				CreateBlock(0, blocktype, fPos, fAng, KvGetFloat(g_hBlocksKV, "attrib1"), KvGetFloat(g_hBlocksKV, "attrib2"), transparency)
			}
			else if(blocktype == 28)
			{
				CreateBlock(0, blocktype, fPos, fAng, KvGetFloat(g_hBlocksKV, "attrib1"), 0.0, transparency) 
			}
			else
			{
				CreateBlock(0, blocktype, fPos, fAng, 0.0, 0.0, transparency);
			}
			blocks++;
		}
	} while (KvGotoNextKey(g_hBlocksKV));
	
	if(msg)
		PrintToChatAll("\x03%s\x04 %d blocks and %d pair of teleporters were loaded.", CHAT_TAG, blocks, teleporters);
}

//public Action:ResetPerform(Handle:timer, any:client)
//{
//	if(!DuckHop[client])
//		DuckHop_Perform[client] = false
//}
 
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	/*
	if(IsPlayerAlive(client))
	{
		if (buttons & IN_DUCK)
		{
			if (!(GetEntityFlags(client) & FL_ONGROUND))
			{
				if (!(GetEntityMoveType(client) & MOVETYPE_LADDER))
				{
				//	if(GetEntProp(client, Prop_Data, "m_nWaterLevel") <= 1)
				//	{
						DuckHop[client] = true;
				//	}
				}
			}
			else
			{
				decl Float:velocity[3]
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
				if(DuckHop[client])
				{
					DuckHop[client] = false
					
					DuckHop_Perform[client] = true
					DuckHop_Velocity[client][0] = velocity[0] * 5.5
					DuckHop_Velocity[client][1] = velocity[1] * 5.5 // velocity_duck
				}
				if(DuckHop_Perform[client])
				{
					if(buttons & IN_JUMP)
					{
						DuckHop_Velocity[client][2] = velocity[2]
						TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, DuckHop_Velocity[client])
					
					}
					else
					{
						CreateTimer(0.80, ResetPerform, client)
					}
				}
			}
		}
	}*/
	
	new Float:fPos[3];
	new Float:fPos2[3];
	GetClientAbsOrigin(client, fPos);
	fPos[2]+=50.0;
	
	//new block_ent = GetClientAimTarget(client, false);
	
	for(new a=MaxClients+1;a<2048;++a)
	{
		if(GetClientTeam(client)<2)
			continue;

		if(g_iBlocks[a]==10)
		{
			GetEntPropVector(a, Prop_Data, "m_vecOrigin", fPos2);
			if(fPos[0] - 20.0 < fPos2[0] < fPos[0] + 20.0 && fPos[1] - 20.0 < fPos2[1] < fPos[1] + 20.0 && fPos[2] - 60.0 < fPos2[2] < fPos[2] + 60.0)
			{
				new iTeam=GetClientTeam(client);
				if(iTeam==2)
					PrintToChatAll("\x03%s\x04 %N has nuked the Counter-Terrorist team.", CHAT_TAG, client);
				else if(iTeam==3)
					PrintToChatAll("\x03%s\x04 %N has nuked the Terrorist team.", CHAT_TAG, client);
					
				g_iBlocks[a]=0;
				
				EmitSoundToAll(NUKE_SOUND_PATH)
				
				for(new i=1;i<=MaxClients;++i)
				{
					if(IsClientInGame(i))
					{
						if(IsPlayerAlive(i))
						{
							if((iTeam == 2 && GetClientTeam(i)==3) || (iTeam == 3 && GetClientTeam(i)==2))
							{
								if(!g_bInv[i])
									ForcePlayerSuicide(i);
							}
						}
					}
				}
				break;
			}
		} 
		else if(g_iBlocks[a]==14) // CT Barrier
		{
			if(GetClientTeam(client)==3)
			{
				if(!g_bLocked[client])
				{
					GetEntPropVector(a, Prop_Data, "m_vecOrigin", fPos2);
					if(fPos[0] - 60.0 < fPos2[0] < fPos[0] + 60.0 && fPos[1] - 60.0 < fPos2[1] < fPos[1] + 60.0 && fPos[2] - 120.0 < fPos2[2] < fPos[2] + 120.0)
					{
						new Float:fVelocity[3];
						GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity); 
						ScaleVector(fVelocity, -2.0);
						fVelocity[2] = 0.0;
						g_bLocked[client]=true;
						CreateTimer(0.1, ResetLock, client);

						TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
					}
				}
			}
		}
		else if(g_iBlocks[a]==15) // T Barrier
		{
		
			if(GetClientTeam(client)==2)
			{
				if(!g_bLocked[client])
				{
					GetEntPropVector(a, Prop_Data, "m_vecOrigin", fPos2);
					if(fPos[0] - 60.0 < fPos2[0] < fPos[0] + 60.0 && fPos[1] - 60.0 < fPos2[1] < fPos[1] + 60.0 && fPos[2] - 120.0 < fPos2[2] < fPos[2] + 120.0)
					{
						new Float:fVelocity[3];
						GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity); 
						ScaleVector(fVelocity, -2.0);
						fVelocity[2] = 0.0;
						g_bLocked[client]=true;
						CreateTimer(0.1, ResetLock, client);

						TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
					}
				}
			}
		} 
		else if(g_iBlocks[a]==19 || g_iBlocks[a]==5) // NOFALLDAMAGE
		{
			GetEntPropVector(a, Prop_Data, "m_vecOrigin", fPos2);
			if(GetVectorDistance(fPos, fPos2)<=100.0)
			{
				if(!g_bNoFallDmg[client])
					CreateTimer(0.2, ResetNoFall, client);
				g_bNoFallDmg[client]=true;
			}
		} else if(g_iTeleporters[a]>1 && 2<=GetClientTeam(client)<=3)
		{
			GetEntPropVector(a, Prop_Data, "m_vecOrigin", fPos2);
			if(IsValidBlock(g_iTeleporters[a]))
			{
				if(fPos[0] - 32.0 < fPos2[0] < fPos[0] + 32.0 && fPos[1] - 32.0 < fPos2[1] < fPos[1] + 32.0 && fPos[2] - 64.0 < fPos2[2] < fPos[2] + 64.0)
				{
					new String:sound[512];
					GetConVarString(g_hTeleSound, sound, sizeof(sound));
					GetEntPropVector(g_iTeleporters[a], Prop_Data, "m_vecOrigin", fPos2);
					TeleportEntity(client, fPos2, NULL_VECTOR, NULL_VECTOR);
					EmitSoundToClient(client, TELE_SOUND_PATH);
				}
			}
		}
	}
	if(g_iDragEnt[client] != 0)
	{
		if(IsValidEdict(g_iDragEnt[client]))
		{
			//	new ent = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			//	if(ent != -1)
			//	{
			//		SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", 10000.0);
			//		SetEntPropFloat(ent, Prop_Send, "m_flNextSecondaryAttack", 10000.0);
			//	}
			
			new Float:vecDir[3], Float:vecPos[3], Float:vecVel[3];
			new Float:viewang[3];
			
			GetClientEyeAngles(client, viewang);
			GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
			GetClientEyePosition(client, vecPos);
			
			vecPos[0]+=vecDir[0]*200;
			vecPos[1]+=vecDir[1]*200;
			vecPos[2]+=vecDir[2]*200;
			
			GetEntPropVector(g_iDragEnt[client], Prop_Send, "m_vecOrigin", vecDir);
			
			new Float:fPos3[3];
			
			new bool:bSnap = false;
			new bool:bGroup = g_bGroups[client][g_iDragEnt[client]];
			
			if(g_bSnapping[client] && (FloatAbs(g_fClientAngles[client][1]) - FloatAbs(angles[1])) < 2.0 && !bGroup)
			{
				for(new i=MaxClients+1;i<2048;++i)
				{
					if(IsValidBlock(i) && i != g_iDragEnt[client])
					{
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", fPos3);
						if(GetVectorDistance(vecDir, fPos3) <= 60.0+g_fSnappingGap[client])
						{
							bSnap = true;
							new Float:d1, Float:d2, Float:d3, Float:d4, Float:d5, Float:d6;
							if(g_fAngles[i][1] == 0.0 && g_fAngles[i][2]==0.0)
							{
								fPos3[0]+=64.0;
								d1=GetVectorDistance(vecDir, fPos3);
								fPos3[0]-=128.0;
								d2=GetVectorDistance(vecDir, fPos3);
								fPos3[0]+=64.0;
								fPos3[1]+=64.0;
								d3=GetVectorDistance(vecDir, fPos3);
								fPos3[1]-=128.0;
								d4=GetVectorDistance(vecDir, fPos3);
								fPos3[1]+=64.0;
								fPos3[2]+=8.0;
								d5=GetVectorDistance(vecDir, fPos3);
								fPos3[2]-=16.0;
								d6=GetVectorDistance(vecDir, fPos3);
								fPos3[2]+=8.0;
								
								vecDir = fPos3;
								if(d1 < d2 && d1 < d3 && d1 < d4 && d1 < d5 && d1 < d6)
									vecDir[0]+=64.0+g_fSnappingGap[client];
								else if(d2 < d1 && d2 < d3 && d2 < d4 && d2 < d5 && d2 < d6)
									vecDir[0]-=64.0+g_fSnappingGap[client];
								else if(d3 < d1 && d3 < d2 && d3 < d4 && d3 < d5 && d3 < d6)
									vecDir[1]+=64.0+g_fSnappingGap[client];
								else if(d4 < d1 && d4 < d2 && d4 < d3 && d4 < d5 && d4 < d6)
									vecDir[1]-=64.0+g_fSnappingGap[client];
								else if(d5 < d1 && d5 < d2 && d5 < d3 && d5 < d4 && d5 < d6)
									vecDir[2]+=8.0+g_fSnappingGap[client];
								else if(d6 < d1 && d6 < d2 && d6 < d3 && d6 < d4 && d6 < d5)
									vecDir[2]-=8.0+g_fSnappingGap[client];
							} else if(g_fAngles[i][1]==0.0 && g_fAngles[i][2] == 90.0)
							{
								fPos3[0]+=64.0;
								d1=GetVectorDistance(vecDir, fPos3);
								fPos3[0]-=128.0;
								d2=GetVectorDistance(vecDir, fPos3);
								fPos3[0]+=64.0;
								fPos3[1]+=8.0;
								d3=GetVectorDistance(vecDir, fPos3);
								fPos3[1]-=16.0;
								d4=GetVectorDistance(vecDir, fPos3);
								fPos3[1]+=8.0;
								fPos3[2]+=64.0;
								d5=GetVectorDistance(vecDir, fPos3);
								fPos3[2]-=128.0;
								d6=GetVectorDistance(vecDir, fPos3);
								fPos3[2]+=64.0;
								
								vecDir = fPos3;
								if(d1 < d2 && d1 < d3 && d1 < d4 && d1 < d5 && d1 < d6)
									vecDir[0]+=64.0+g_fSnappingGap[client];
								else if(d2 < d1 && d2 < d3 && d2 < d4 && d2 < d5 && d2 < d6)
									vecDir[0]-=64.0+g_fSnappingGap[client];
								else if(d3 < d1 && d3 < d2 && d3 < d4 && d3 < d5 && d3 < d6)
									vecDir[1]+=8.0+g_fSnappingGap[client];
								else if(d4 < d1 && d4 < d2 && d4 < d3 && d4 < d5 && d4 < d6)
									vecDir[1]-=8.0+g_fSnappingGap[client];
								else if(d5 < d1 && d5 < d2 && d5 < d3 && d5 < d4 && d5 < d6)
									vecDir[2]+=64.0+g_fSnappingGap[client];
								else if(d6 < d1 && d6 < d2 && d6 < d3 && d6 < d4 && d6 < d5)
									vecDir[2]-=64.0+g_fSnappingGap[client];
							}
							else
							{
								fPos3[0]+=8.0;
								d1=GetVectorDistance(vecDir, fPos3);
								fPos3[0]-=16.0;
								d2=GetVectorDistance(vecDir, fPos3);
								fPos3[0]+=8.0;
								fPos3[1]+=64.0;
								d3=GetVectorDistance(vecDir, fPos3);
								fPos3[1]-=128.0;
								d4=GetVectorDistance(vecDir, fPos3);
								fPos3[1]+=64.0;
								fPos3[2]+=64.0;
								d5=GetVectorDistance(vecDir, fPos3);
								fPos3[2]-=128.0;
								d6=GetVectorDistance(vecDir, fPos3);
								fPos3[2]+=64.0;
								
								vecDir = fPos3;
								if(d1 < d2 && d1 < d3 && d1 < d4 && d1 < d5 && d1 < d6)
									vecDir[0]+=8.0+g_fSnappingGap[client];
								else if(d2 < d1 && d2 < d3 && d2 < d4 && d2 < d5 && d2 < d6)
									vecDir[0]-=8.0+g_fSnappingGap[client];
								else if(d3 < d1 && d3 < d2 && d3 < d4 && d3 < d5 && d3 < d6)
									vecDir[1]+=64.0+g_fSnappingGap[client];
								else if(d4 < d1 && d4 < d2 && d4 < d3 && d4 < d5 && d4 < d6)
									vecDir[1]-=64.0+g_fSnappingGap[client];
								else if(d5 < d1 && d5 < d2 && d5 < d3 && d5 < d4 && d5 < d6)
									vecDir[2]+=64.0+g_fSnappingGap[client];
								else if(d6 < d1 && d6 < d2 && d6 < d3 && d6 < d4 && d6 < d5)
									vecDir[2]-=64.0+g_fSnappingGap[client];
							}
							
							g_fAngles[g_iDragEnt[client]] = g_fAngles[i];
							break;
						}
					}
				}
			}
			
			if(!bSnap)
			{
				SubtractVectors(vecPos, vecDir, vecVel);
				ScaleVector(vecVel, 10.0);
				TeleportEntity(g_iDragEnt[client], NULL_VECTOR, g_fAngles[g_iDragEnt[client]], vecVel);
				if(bGroup)
				{
					new Float:playerPos[3];
					GetClientEyePosition(client, playerPos);
					new Float:vecOrig[3];
					vecOrig = vecPos;
					
					for(new i=MaxClients+1;i<2048;++i)
					{
						if(IsValidBlock(i) && i != g_iDragEnt[client] && g_bGroups[client][i])
						{
							vecPos = vecOrig;
							SubtractVectors(vecPos, vecDir, vecVel);
							ScaleVector(vecVel, 10.0);
							
							TeleportEntity(i, NULL_VECTOR, g_fAngles[i], vecVel);
						}
					}
				}
			}
			else
			{
				SetEntityMoveType(g_iDragEnt[client], MOVETYPE_NONE);
				AcceptEntityInput(g_iDragEnt[client], "disablemotion");
				new Float:nvel[3] = {0.0, 0.0, 0.0};
				TeleportEntity(g_iDragEnt[client], vecDir, g_fAngles[g_iDragEnt[client]], nvel);
				
				g_iDragEnt[client] = 0
				
				DisplayMenu(CreateMainMenu(client), client, 0);
			}
		}
		else
		{
			g_iDragEnt[client] = 0;
		}
	}
	
	g_fClientAngles[client]=angles;
	
	return Plugin_Continue;
}

public Action:ResetLock(Handle:timer, any:client)
{
	if(!IsClientInGame(client))
		return Plugin_Stop;
	g_bLocked[client]=false;
	new Float:fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity); 
	ScaleVector(fVelocity, -0.5);
	return Plugin_Stop;
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data)
		return false;
	return true;
}

public Action:Command_BlockBuilder(client, args)
{
//	if(!(GetUserFlagBits(client) & ADMFLAG_CUSTOM1 || GetUserFlagBits(client) & ADMFLAG_ROOT))
//	{
//		PrintToChat(client, "\x03%s\x04 You don't have permission to access this.", CHAT_TAG);
//		return Plugin_Handled;
//	}
	
	new Handle:menu = CreateMainMenu(client);
	
	DisplayMenu(menu, client, 30); 
	return Plugin_Handled;
}

public Handler_BlockBuilder(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new bool:bDisplayMenu = true;
		if(param2==0)
		{
			bDisplayMenu = false;
			DisplayMenu(CreateBlocksMenu(), client, 0); 
		} else if(param2==1)
		{
			if(g_iDragEnt[client] == 0)
			{
				new ent = GetClientAimTarget(client, false);
				if(IsValidBlock(ent))
				{
					g_iDragEnt[client] = ent;
					if(g_bGroups[client][g_iDragEnt[client]])
					{
						for(new i=0;i<2048;++i)
						{
							if(IsValidBlock(i) && g_bGroups[client][i])
							{
								SetEntityMoveType(i, MOVETYPE_VPHYSICS);
								AcceptEntityInput(i, "enablemotion");
							}
						}
					}
					else
					{
						SetEntityMoveType(g_iDragEnt[client], MOVETYPE_VPHYSICS);
						AcceptEntityInput(g_iDragEnt[client], "enablemotion");
					}
					//PrintToChat(client, MESS, "Block has been grabbed.");
				}
				else
				{
					CreateBlock(client);
				}
			}
			else
			{
				new Float:fVelocity[3] = {0.0, 0.0, 0.0};
				TeleportEntity(g_iDragEnt[client], NULL_VECTOR, g_fAngles[g_iDragEnt[client]], fVelocity);
				if(g_bGroups[client][g_iDragEnt[client]])
				{
					for(new i=0;i<2048;++i)
					{
						if(IsValidBlock(i) && g_bGroups[client][i])
						{
							SetEntityMoveType(i, MOVETYPE_NONE);
							AcceptEntityInput(i, "disablemotion");
						}
					}
				}
				else
				{
					SetEntityMoveType(g_iDragEnt[client], MOVETYPE_NONE);
					AcceptEntityInput(g_iDragEnt[client], "disablemotion");
				}
				g_iDragEnt[client] = 0;
				//PrintToChat(client, MESS, "Block has been released.");
			}
		} else if(param2==2)
		{
			new ent = GetClientAimTarget(client, false);
			if(IsValidBlock(ent))
			{
				decl Float:vAng[3];
				GetEntPropVector(ent, Prop_Data, "m_angRotation", vAng);

				if (vAng[1])
				{
					vAng[1] = 0.0;
					vAng[2] = 0.0;
				}
				else if (vAng[2])
					vAng[1] = 90.0;
				else
					vAng[2] = 90.0;
					
				g_fAngles[ent] = vAng;
					
				TeleportEntity(ent, NULL_VECTOR, vAng, NULL_VECTOR);
			}
			else
			{
				PrintToChat(client, "\x03%s\x04 You must aim at a block.", CHAT_TAG);
			}
		} else if(param2==3)
		{
			new ent = GetClientAimTarget(client, false);
			if(IsValidBlock(ent) && g_iTeleporters[ent]==-1)
			{
				if(g_iBlockSelection[client]==g_iBlocks[ent])
				{
					PrintToChat(client, "%s The block type is the same, there's no need to change.", CHAT_TAG);
				}
				else
				{
					g_iBlocks[ent]=g_iBlockSelection[client];
					SetEntityModel(ent, g_eBlocks[g_iBlockSelection[client]][ModelPath]);
					//PrintToChat(client, "%sSuccessfully converted the block to \x03%s\x04.", CHAT_TAG, g_eBlocks[g_iBlockSelection[client]][BlockName]);
				}
			}
			else
			{
				PrintToChat(client, "\x03%s\x04 You must aim at a block.", CHAT_TAG);
			}
		} else if(param2==4)
		{
				new ent = GetClientAimTarget(client, false);
				if(IsValidBlock(ent))
				{
					AcceptEntityInput(ent, "Kill");
					g_iBlocks[ent]=-1;
					if(g_iTeleporters[ent]>=1)
					{
						if(g_iTeleporters[ent]>1 && IsValidBlock(g_iTeleporters[ent]))
						{
							AcceptEntityInput(g_iTeleporters[ent], "Kill");
							g_iTeleporters[g_iTeleporters[ent]] = -1;
						} else if(g_iTeleporters[ent]==1)
						{
							for(new i=MaxClients+1;i<2048;++i)
							{
								if(g_iTeleporters[i]==ent)
								{
									if(IsValidBlock(i))
										AcceptEntityInput(i, "Kill");
									g_iTeleporters[i] = -1;
									break;
								}
							}
						}
						
						g_iTeleporters[ent]=-1;
					}
					//PrintToChat(client, MESS, "Block has been deleted.");
				}
				else
				{
					PrintToChat(client, "\x03%s\x04 You must aim at a block.", CHAT_TAG);
				}
		} else if(param2==5)
		{
			if(GetEntityMoveType(client) != MOVETYPE_NOCLIP)
			{
				SetEntityMoveType(client, MOVETYPE_NOCLIP);
			}
			else
			{
				SetEntityMoveType(client, MOVETYPE_ISOMETRIC);
			}
		} else if(param2==6)
		{
			if(GetEntProp(client, Prop_Data, "m_takedamage", 1) == 2)
			{
				SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
			}
			else
			{
				SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
			}
		} else if(param2==7)
		{
			bDisplayMenu=false;
			DisplayMenu(CreateTeleportMenu(client), client, 0);
		} else if(param2==10)
		{
			bDisplayMenu=false;
			DisplayMenu(CreateOptionsMenu(client), client, 0);
		}
		else if(param2==9)
		{
			new ent = GetClientAimTarget(client, false);
			if(IsValidBlock(ent))
			{
				if(g_iBlocks[ent] == 5) // TRAMPOLINE
				{
					bDisplayMenu=false;
					CurrentModifier[client] = ent
					AdjustTrampolineForce(client)

				}
				else if(g_iBlocks[ent] == 6)
				{
					bDisplayMenu=false;
					CurrentModifier[client] = ent
					ShowMenu3E(client)
				}
				else if(g_iBlocks[ent] == 18)
				{
					bDisplayMenu=false;
					CurrentModifier[client] = ent
					ShowMenuDelayed_NoSlowdown(client)
				}
				else if(g_iBlocks[ent] == 28)
				{
					bDisplayMenu=false;
					CurrentModifier[client] = ent
					ShowMenuDelayed(client)
				}
				else
				{
					bDisplayMenu=false;
					DisplayMenu(CreateMainMenu(client), client, 0); 
					PrintToChat(client, "\x03%s\x04 There are no properties available for this block.", CHAT_TAG);
				}
			}
			else
			{
					bDisplayMenu=false;
					DisplayMenu(CreateMainMenu(client), client, 0); 
					PrintToChat(client, "\x03%s\x04 You have to aim at the block to change it's properties.", CHAT_TAG);
			}
		}
		else if(param2==8)
		{
			new ent = GetClientAimTarget(client, false);
			if(IsValidBlock(ent))
			{
				bDisplayMenu=false;
				CurrentModifier[client] = ent
				Command_BlockAlpha(client)
			}
		}
		if(bDisplayMenu)
			DisplayMenu(CreateMainMenu(client), client, 0); 
	}
}

public Command_BlockAlpha(client)
{
	new Handle:menu = CreateMenu(BB_ALPHA, MenuAction_Select | MenuAction_End);
	SetMenuTitle(menu, "Block Transparency");
	AddMenuItem(menu, "20", "20");
	AddMenuItem(menu, "40", "40");
	AddMenuItem(menu, "60", "60");
	AddMenuItem(menu, "80", "80");
	AddMenuItem(menu, "100", "100");
	AddMenuItem(menu, "120", "120");
	AddMenuItem(menu, "140", "140");
	AddMenuItem(menu, "160", "160");
	AddMenuItem(menu, "180", "180");
	AddMenuItem(menu, "200", "200");
	AddMenuItem(menu, "220", "240");
	AddMenuItem(menu, "250", "250");
	AddMenuItem(menu, "255", "255 (DEFAULT)");
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

 
public BB_ALPHA(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[16];
			GetMenuItem(menu, param2, item, sizeof(item));
			SetEntityRenderMode(CurrentModifier[client], RENDER_TRANSCOLOR)
			SetEntityRenderColor(CurrentModifier[client], 255, 255, 255, StringToInt(item))
			DisplayMenu(CreateMainMenu(client), client, 0);
			PrintToChat(client, "\x03%s\x04 Block's Transparency has been adjusted.", CHAT_TAG);
			Block_Transparency[CurrentModifier[client]] = StringToInt(item);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public AdjustTrampolineForce(client)
{
		new Handle:menu = CreateMenu(TFCH2, MenuAction_Select | MenuAction_End);
		SetMenuTitle(menu, "Adjust Trampoline Force:");
		AddMenuItem(menu, "1000", "1000");
		AddMenuItem(menu, "900", "900");
		AddMenuItem(menu, "800", "800");
		AddMenuItem(menu, "700", "700");
		AddMenuItem(menu, "600", "600");
		AddMenuItem(menu, "500", "500 (DEFAULT)");
		AddMenuItem(menu, "400", "400");
		AddMenuItem(menu, "300", "300");

		DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
 
public TFCH2(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[16];
			GetMenuItem(menu, param2, item, sizeof(item));
			TrampolineForce[CurrentModifier[client]] = StringToFloat(item)
			DisplayMenu(CreateMainMenu(client), client, 0);
			PrintToChat(client, "\x03%s\x04 Trampoline has been adjusted.", CHAT_TAG);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public Handle:CreateTeleportMenu(client)
{
	new Handle:menu = CreateMenu(Handler_Teleport);
	SetMenuTitle(menu, "Teleport Menu");
	if(g_iCurrentTele[client]==-1)
		AddMenuItem(menu, "0", "Teleport Start");
	else
		AddMenuItem(menu, "0", "Cancel teleport");
	AddMenuItem(menu, "1", "Teleport End");
	AddMenuItem(menu, "2", "Swap Teleport Start/End");
	AddMenuItem(menu, "3", "Delete Teleport");
	AddMenuItem(menu, "4", "Show Teleport Path");
	SetMenuExitBackButton(menu, true);
	return menu;
}

public Handle:CreateBlocksMenu()
{
	new Handle:menu = CreateMenu(Handler_Blocks);
	decl String:szItem[4];
	SetMenuTitle(menu, "Block Type Menu");
	for (new i; i < sizeof(g_eBlocks); i++)
	{
		IntToString(i, szItem, sizeof(szItem));
		AddMenuItem(menu, szItem, g_eBlocks[i][BlockName]);
	}
	SetMenuExitBackButton(menu, true);
	return menu;
}

public Handle:CreateMainMenu(client)
{
	new Handle:menu = CreateMenu(Handler_BlockBuilder);

	SetMenuTitle(menu, "Blockmaker");
	
	new String:sInfo[256];
	Format(sInfo, sizeof(sInfo), "Block: %s", g_eBlocks[g_iBlockSelection[client]][BlockName]);
	AddMenuItem(menu, "0", sInfo);
	if(g_iDragEnt[client]==0)
		AddMenuItem(menu, "1", "Place Block");
	else
		AddMenuItem(menu, "1", "Release Block");
	AddMenuItem(menu, "2", "Rotate Block");
	AddMenuItem(menu, "3", "Convert Block");
	AddMenuItem(menu, "4", "Delete Block\n \n");
 
//	new bRoot = (GetUserFlagBits(client) & ADMFLAG_ROOT || GetUserFlagBits(client) & ReadFlagString("p") ?true:false);
	if(GetEntityMoveType(client) != MOVETYPE_NOCLIP)
//		AddMenuItem(menu, "5", "No Clip: Off", (bRoot?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));
		AddMenuItem(menu, "5", "No Clip: Off");
	else
//		AddMenuItem(menu, "5", "No Clip: On", (bRoot?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));
		AddMenuItem(menu, "5", "No Clip: On");
	if(GetEntProp(client, Prop_Data, "m_takedamage", 1) == 2)
//		AddMenuItem(menu, "6", "Godmode: Off\n \n", (bRoot?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));
		AddMenuItem(menu, "6", "Godmode: Off\n \n");
	else
//		AddMenuItem(menu, "6", "Godmode: On\n \n", (bRoot?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));
		AddMenuItem(menu, "6", "Godmode: On\n \n");

	AddMenuItem(menu, "7", "Teleport Builder");
	AddMenuItem(menu, "8", "Block Transparency");
	AddMenuItem(menu, "9", "Block Properties");
	AddMenuItem(menu, "10", "More Options");
	SetMenuExitButton(menu, true);
	g_hClientMenu[client] = menu;
	return menu;
}

public Handle:CreateOptionsMenu(client)
{
	new Handle:menu = CreateMenu(Handler_Options);
	SetMenuTitle(menu, "Options Menu");
	
	if(g_bSnapping[client])
		AddMenuItem(menu, "0", "Snapping: On");
	else
		AddMenuItem(menu, "0", "Snapping: Off");
	
		
	new String:sText[256];
	Format(sText, sizeof(sText), "Snapping gap: %.1f\n \n", g_fSnappingGap[client]);
	AddMenuItem(menu, "1", sText);
	
	AddMenuItem(menu, "2", "Add to group");
	AddMenuItem(menu, "3", "Clear group\n \n");

	new bRoot = (GetUserFlagBits(client) & ADMFLAG_ROOT || GetUserFlagBits(client) & ReadFlagString("p") ?true:false);
	
//	AddMenuItem(menu, "4", "Load from file");
	AddMenuItem(menu, "4", "Load from file", (bRoot?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));
//	AddMenuItem(menu, "5", "Save to file\n \n");
	AddMenuItem(menu, "5", "Save to file\n \n", (bRoot?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));
	
//	AddMenuItem(menu, "6", "Delete all blocks");
	AddMenuItem(menu, "6", "Delete all blocks", (bRoot?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));
//	AddMenuItem(menu, "7", "Delete all teleporters");
	AddMenuItem(menu, "7", "Delete all teleporters", (bRoot?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));

	SetMenuExitBackButton(menu, true);
	return menu;
}

CreateTeleportEntrance(client, Float:fPos[3]={0.0, 0.0, 0.0})
{
	new Float:vecDir[3], Float:vecPos[3], Float:viewang[3];
	if(client > 0)
	{
		GetClientEyeAngles(client, viewang);
		GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
		GetClientEyePosition(client, vecPos);
		vecPos[0]+=vecDir[0]*100;
		vecPos[1]+=vecDir[1]*100;
		vecPos[2]+=vecDir[2]*100;
	}
	else
	{
		vecPos = fPos;
	}

	new ent = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(ent, "model", "models/blockbuilder/tele_start.mdl");
	TeleportEntity(ent, vecPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(ent);
	
	SetEntityMoveType(ent, MOVETYPE_NONE);
	AcceptEntityInput(ent, "disablemotion");
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);
	
	g_iTeleporters[ent]=1;
	g_iCurrentTele[client]=ent;
	
	SDKHook(ent, SDKHook_StartTouch, OnStartTouch);
	
	return ent;
}

CreateTeleportExit(client, Float:fPos[3]={0.0, 0.0, 0.0})
{
	new Float:vecDir[3], Float:vecPos[3], Float:viewang[3];
	if(client > 0)
	{
		GetClientEyeAngles(client, viewang);
		GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
		GetClientEyePosition(client, vecPos);
		vecPos[0]+=vecDir[0]*100;
		vecPos[1]+=vecDir[1]*100;
		vecPos[2]+=vecDir[2]*100;
	}
	else
	{
		vecPos = fPos;
	}

	new ent = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(ent, "model", "models/blockbuilder/tele_end.mdl");
	TeleportEntity(ent, vecPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(ent);
	
	SetEntityMoveType(ent, MOVETYPE_NONE);
	AcceptEntityInput(ent, "disablemotion");
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);
	
	g_iTeleporters[ent]=1;
	
	return ent;
}

CreateBlock(client, blocktype=0, Float:fPos[3]={0.0, 0.0, 0.0}, Float:fAng[3]={0.0, 0.0, 0.0}, Float:attrib1=0.0, Float:attrib2=0.0, transparency=0)
{ 
	new Float:vecDir[3], Float:vecPos[3], Float:viewang[3];
	if(client > 0)
	{
		GetClientEyeAngles(client, viewang);
		GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
		GetClientEyePosition(client, vecPos);
		vecPos[0]+=vecDir[0]*100;
		vecPos[1]+=vecDir[1]*100;
		vecPos[2]+=vecDir[2]*100;
	}
	else
	{
		vecPos = fPos;
	}

	new block_entity = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(block_entity, "model", g_eBlocks[(client>0?g_iBlockSelection[client]:blocktype)][ModelPath]);
	TeleportEntity(block_entity, vecPos, fAng, NULL_VECTOR);
	DispatchSpawn(block_entity);
	
	SetEntityMoveType(block_entity, MOVETYPE_NONE);
	if(transparency > 0)
	{ 
		SetEntityRenderMode(block_entity, RENDER_TRANSCOLOR)
		SetEntityRenderColor(block_entity, 255, 255, 255, transparency)
		Block_Transparency[block_entity] = transparency;
	}
	else
	{
		Block_Transparency[block_entity] = -1;
	}
	AcceptEntityInput(block_entity, "disablemotion");
	if(14 <= (client>0?g_iBlockSelection[client]:blocktype) <= 15)
	{
		SetEntProp(block_entity, Prop_Data, "m_CollisionGroup", 2);
	}
	g_iBlocks[block_entity]=(client>0?g_iBlockSelection[client]:blocktype);
	if(g_iBlocks[block_entity] == 5)
	{
		if(attrib1 == 0)
		{
			TrampolineForce[block_entity] = 500.0
		}
		else
		{
			TrampolineForce[block_entity] = attrib1
		}
		CurrentModifier[client] = block_entity

		if(client > 0)
		{
			CreateTimer(0.10, ShowMenu, client)
		}
		else
		{
			SDKHook(block_entity, SDKHook_StartTouch, OnStartTouch);
			SDKHook(block_entity, SDKHook_Touch, OnTouch);
			SDKHook(block_entity, SDKHook_EndTouch, OnEndTouch);
		}
	}
	else if(g_iBlocks[block_entity] == 6)
	{
		if(attrib1 == 0)
		{
			SpeedBoostForce_1[block_entity] = 800.0
		}
		else
		{
			SpeedBoostForce_1[block_entity] = attrib1
		}
		if(attrib2 == 0)
		{
			SpeedBoostForce_2[block_entity] = 260.0
		}
		else
		{
			SpeedBoostForce_2[block_entity] = attrib2
		}
		CurrentModifier[client] = block_entity
		if(client > 0)
		{
			CreateTimer(0.10, ShowMenu3, client)
		}
		else
		{
			SDKHook(block_entity, SDKHook_StartTouch, OnStartTouch);
			SDKHook(block_entity, SDKHook_Touch, OnTouch);
			SDKHook(block_entity, SDKHook_EndTouch, OnEndTouch);
		}
	}
//	else if(g_iBlocks[block_entity] == 8)
//	{
//		SetEntityRenderColor(block_entity, 255, 255, 255 ,75);
//		SetEntityRenderMode(block_entity, RENDER_GLOW)
//	}
//	else if(g_iBlocks[block_entity] == 14) // CT Barrier
//	{
//		SDKHook(block_entity, SDKHook_ShouldCollide, ShouldCollide_CT)
//		PrintToChatAll("CT Barreir touched now")
//	}
//	else if(g_iBlocks[block_entity] == 15) // T Barrier
//	{
//		SDKHook(block_entity, SDKHook_ShouldCollide, ShouldCollide_T)
//		PrintToChatAll("TT Barier touched now")
//	}
	else if(g_iBlocks[block_entity] == 28)
	{
		CurrentModifier[client] = block_entity
		if(attrib1 == 0)
		{
			SpeedBoostForce_1[block_entity] = 1.5
		}
		else
		{
			SpeedBoostForce_1[block_entity] = attrib1
		}
		if(client > 0)
		{
			CreateTimer(0.10, ShowMenuDelayed2, client)
		}
		else
		{
			SDKHook(block_entity, SDKHook_StartTouch, OnStartTouch);
			SDKHook(block_entity, SDKHook_Touch, OnTouch);
			SDKHook(block_entity, SDKHook_EndTouch, OnEndTouch);
		}
		
	}
	else if(g_iBlocks[block_entity] == 18)
	{
		CurrentModifier[client] = block_entity
		if(attrib1 == 0)
		{
			SpeedBoostForce_1[block_entity] = 1.5
		}
		else
		{
			SpeedBoostForce_1[block_entity] = attrib1
		}
		if(client > 0)
		{
			CreateTimer(0.10, ShowMenuDelayed_NoSlowdown2, client);
		}
		else
		{
			SDKHook(block_entity, SDKHook_StartTouch, OnStartTouch);
			SDKHook(block_entity, SDKHook_Touch, OnTouch);
			SDKHook(block_entity, SDKHook_EndTouch, OnEndTouch);
		}
		
	}
	else
	{
		SDKHook(block_entity, SDKHook_StartTouch, OnStartTouch);
		SDKHook(block_entity, SDKHook_Touch, OnTouch);
		SDKHook(block_entity, SDKHook_EndTouch, OnEndTouch);
	}

	g_fAngles[block_entity]=fAng;
	
	//PrintToChat(client, "%sSuccessfully spawned block \x03%s\x04.", CHAT_TAG, g_eBlocks[g_iBlockSelection[client]][BlockName]);
	return block_entity;
}
 /*
public bool:ShouldCollide_T(entity, collisiongroup, contentsmask, bool:originalResult)
{
	if ((contentsmask & CONTENTS_TEAM2 == CONTENTS_TEAM2))
	{
		return false;
	}
	return true;
}

public bool:ShouldCollide_CT(entity, collisiongroup, contentsmask, bool:originalResult)
{
	if ((contentsmask & CONTENTS_TEAM1 == CONTENTS_TEAM1))
	{
		return false;
	}
	return true;
}*/

public Action:ShowMenu(Handle:timer, any:client)
{
		new Handle:menu = CreateMenu(TFCH, MenuAction_Select | MenuAction_End);
		SetMenuTitle(menu, "Choose Trampoline Force:");
		AddMenuItem(menu, "1000", "1000");
		AddMenuItem(menu, "900", "900");
		AddMenuItem(menu, "800", "800");
		AddMenuItem(menu, "700", "700");
		AddMenuItem(menu, "600", "600");
		AddMenuItem(menu, "500", "500 (DEFAULT)");
		AddMenuItem(menu, "400", "400");
		AddMenuItem(menu, "300", "300");

		DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
 
public TFCH(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[16];
			GetMenuItem(menu, param2, item, sizeof(item));
			TrampolineForce[CurrentModifier[client]] = StringToFloat(item)
			
			SDKHook(CurrentModifier[client], SDKHook_StartTouch, OnStartTouch);
			SDKHook(CurrentModifier[client], SDKHook_Touch, OnTouch);
			SDKHook(CurrentModifier[client], SDKHook_EndTouch, OnEndTouch);
			DisplayMenu(CreateMainMenu(client), client, 0);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(g_bInv[victim] || (g_bNoFallDmg[victim] && damagetype & DMG_FALL))
		return Plugin_Handled;
	return Plugin_Continue;
}

public OnStartTouch(ent1, ent2)
{
	new client = -1;
	new block = -1;
	if(1 <= ent1 <= MaxClients){
		client = ent1;
	}
	else if(1 <= ent2 <= MaxClients){
		client = ent2;
	}
	
	if(IsValidBlock(ent1)){
		block = ent1;
	}
	else if(IsValidBlock(ent2)){
		block = ent2;
	}
	
	if(client == -1 || block == -1){
		return;
	}
	
	if(g_iTeleporters[block]!=-1){
		return;
	}
	if(GetClientTeam(client)<2){
		return;
	}
	
	
	if(g_iBlocks[block]==5) // TRAMP ?
	{
		new Handle:packet = CreateDataPack()
		WritePackCell(packet, client)
		WritePackCell(packet, block)
		CreateTimer(0.0, JumpPlayer, packet)
		g_bNoFallDmg[client]=true;
	} 
	else if(g_iBlocks[block]==6)
	{
		new Handle:packet = CreateDataPack()
		WritePackCell(packet, client)
		WritePackCell(packet, block)
		CreateTimer(0.0, BoostPlayer, packet);
	}
	
	decl Float:block_loc[3]
	GetEntPropVector(block, Prop_Send, "m_vecOrigin", block_loc);
	decl Float:player_loc[3]
	GetClientAbsOrigin(client, player_loc)
	player_loc[2] += TrueForce;
	
	if(FL_ONGROUND && GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == block)
	{
//	new bool:bRandom = false;
	if(g_iBlocks[block]==24)
	{
		if(!g_bRandomCantUse[client])
		{
			g_bRandomCantUse[client] = true;
			new Handle:datapack = CreateDataPack()
			WritePackCell(datapack, client)
			WritePackCell(datapack, RoundIndex)
			if(randomblock_time >= 1.0)
			{
				CreateTimer(randomblock_time, ResetCooldownRandom, datapack)
			}
			else
			{
				CreateTimer(1.0, ResetCooldownRandom, datapack)
			}
			new random = RoundFloat(GetRandomFloat(1.00, 8.00))
			if(random == 1) // Invincibility, Stealth, Camouflage, Boots Of Speed, a slap, or death!
			{
				new Handle:packet_f = CreateDataPack()
				WritePackCell(packet_f, RoundIndex) 
				WritePackCell(packet_f, client)
				CreateTimer(g_eBlocks[7][EffectTime], ResetInv, packet_f);
				CreateTimer(g_eBlocks[7][CooldownTime], ResetInvCooldown, packet_f);
				g_bInv[client]=true;
				g_bInvCanUse[client]=false;
				
			//	CreateLight(client)
				
				new Handle:packet = CreateDataPack()
				WritePackCell(packet, RoundIndex)
				WritePackCell(packet, client)
				WritePackCell(packet, RoundFloat(g_eBlocks[7][EffectTime]))
				WritePackString(packet, "Invincibility")
				
				EmitSoundToClient(client, INVI_SOUND_PATH, block)
				CreateTimer(1.0, TimeLeft, packet)
				PrintToChat(client, "\x03%s\x04 You've rolled an Invincibility from Random Block!", CHAT_TAG);
			}
			else if(random == 2)
			{
				new Handle:packet_f = CreateDataPack()
				WritePackCell(packet_f, RoundIndex)
				WritePackCell(packet_f, client)
				
				CreateTimer(g_eBlocks[8][EffectTime], ResetStealth, packet_f);
				CreateTimer(g_eBlocks[8][CooldownTime], ResetStealthCooldown, packet_f);
				SetEntityRenderMode(client, RENDER_NONE);
				SDKHook(client, SDKHook_SetTransmit, Stealth_SetTransmit)
				g_bStealthCanUse[client]=false;
				
				new Handle:packet = CreateDataPack()
				WritePackCell(packet, RoundIndex)
				WritePackCell(packet, client)
				WritePackCell(packet, RoundFloat(g_eBlocks[8][EffectTime]))
				WritePackString(packet, "Stealth")
				EmitSoundToClient(client, STEALTH_SOUND_PATH, block)
				CreateTimer(1.0, TimeLeft, packet)
				PrintToChat(client, "\x03%s\x04 You've rolled a Stealth from Random Block!", CHAT_TAG);
			}
			else if(random == 3)
			{
				if(GetClientTeam(client)==2)
					SetEntityModel(client, "models/player/ctm_gign.mdl");
				else if(GetClientTeam(client)==3)
					SetEntityModel(client, "models/player/tm_phoenix.mdl");
				g_bCamCanUse[client]=false;
				new Handle:packet_f = CreateDataPack()
				WritePackCell(packet_f, RoundIndex)
				WritePackCell(packet_f, client)
				CreateTimer(g_eBlocks[21][EffectTime], ResetCamouflage, packet_f);
				CreateTimer(g_eBlocks[21][CooldownTime], ResetCamCanUse, packet_f);
				
				new Handle:packet = CreateDataPack()
				WritePackCell(packet, RoundIndex)
				WritePackCell(packet, client)
				WritePackCell(packet, RoundFloat(g_eBlocks[21][EffectTime]))
				WritePackString(packet, "Camouflage")
				EmitSoundToClient(client, CAM_SOUND_PATH, block)
				CreateTimer(1.0, TimeLeft, packet)
				PrintToChat(client, "\x03%s\x04 You've rolled a Camouflage from Random Block!", CHAT_TAG);
			}
			else if(random == 4)
			{
				new Handle:packet_f = CreateDataPack()
				WritePackCell(packet_f, RoundIndex)
				WritePackCell(packet_f, client)
				CreateTimer(g_eBlocks[16][EffectTime], ResetBoots, packet_f);
				CreateTimer(g_eBlocks[16][CooldownTime], ResetBootsCooldown, packet_f);
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 3.0);
				g_bBootsCanUse[client]=false;
				
				new Handle:packet = CreateDataPack()
				WritePackCell(packet, RoundIndex)
				WritePackCell(packet, client)
				WritePackCell(packet, RoundFloat(g_eBlocks[16][EffectTime]))
				WritePackString(packet, "Speed Boost")
				
				EmitSoundToClient(client, BOS_SOUND_PATH, block)
				
				CreateTimer(1.0, TimeLeft, packet)
				PrintToChat(client, "\x03%s\x04 You've rolled a Speed Boost from Random Block!", CHAT_TAG);
			}
			else if(random == 5)
			{
				if(!g_bInv[client])
				{
					SDKHooks_TakeDamage(client, 0, 0, 10000.0);
					PrintToChat(client, "\x03%s\x04 You've rolled a Death from Random Block!", CHAT_TAG);
				}
				else
				{
					PrintToChat(client, "\x03%s\x04 Huh? It looks like you've avoided death from Random Block!", CHAT_TAG);
				}
			}
			else if(random == 6)
			{
				new ent = -1;
				if((ent = GetPlayerWeaponSlot(client, 1)) != -1)
					RemovePlayerItem(client, ent);
			//	ent = GivePlayerItem(client, "weapon_deagle");
				ent = Client_GiveWeaponAndAmmo(client, "weapon_deagle", true, 0, 1, 1, 1);
				SetEntProp(ent, Prop_Data, "m_iClip1", 1);
				SetEntProp(ent, Prop_Data, "m_iClip2", 1);
				SetEntData(client, g_iAmmo+(GetEntData(ent, g_iPrimaryAmmoType)<<2), 0, 4, true);
				PrintToChat(client, "\x03%s\x04 You've rolled a Deagle from Random Block!", CHAT_TAG);
			}
			else if(random == 7)
			{
				new ent = -1;
				if((ent = GetPlayerWeaponSlot(client, 0)) != -1)
					RemovePlayerItem(client, ent);
			//	ent = GivePlayerItem(client, "weapon_awp");
				ent = Client_GiveWeaponAndAmmo(client, "weapon_awp", true, 0, 1, 1, 1);
				SetEntProp(ent, Prop_Data, "m_iClip1", 1);
				SetEntProp(ent, Prop_Data, "m_iClip2", 1);
				SetEntData(client, g_iAmmo+(GetEntData(ent, g_iPrimaryAmmoType)<<2), 0, 4, true);
				PrintToChatAll("\x03%s\x04 %N has rolled from Random Block an AWP, beware CTs!", CHAT_TAG, client);
			}
			else if(random == 8)
			{
				new grenade_random = RoundFloat(GetRandomFloat(1.00, 3.00))
				if(grenade_random == 1)
				{
					GivePlayerItem(client, "weapon_hegrenade");
				}
				else if(grenade_random == 2)
				{
						GivePlayerItem(client, "weapon_flashbang");
				}
				else if(grenade_random == 3)
				{
				        // GivePlayerItem(client, "weapon_smokegrenade");
						GivePlayerItem(client, "weapon_decoy");
				}
				PrintToChat(client, "\x03%s\x04 You've rolled a Grenade from Random Block!", CHAT_TAG);
			}
		}
	}
	else if(g_iBlocks[block]==2)
	{
		if(IsValidHandle(Block_Timers))
			KillTimer(Block_Timers)
		CreateTimer(g_eBlocks[2][CooldownTime], DamagePlayer, client);
	}
	else if(g_iBlocks[block]==3)
	{
		if(IsValidHandle(Block_Timers))
			KillTimer(Block_Timers)
		Block_Timers = CreateTimer(g_eBlocks[3][EffectTime], HealPlayer, client);
	}
	else if(g_iBlocks[block]==4)
	{ 
	}
	else if(g_iBlocks[block]==7)
	{
		if(g_bInvCanUse[client])
		{
			new Handle:packet_f = CreateDataPack()
			WritePackCell(packet_f, RoundIndex)
			WritePackCell(packet_f, client)
			CreateTimer(g_eBlocks[7][EffectTime], ResetInv, packet_f);
			CreateTimer(g_eBlocks[7][CooldownTime], ResetInvCooldown, packet_f);
			g_bInv[client]=true;
			g_bInvCanUse[client]=false;
			
		//	CreateLight(client)
			
			new Handle:packet = CreateDataPack()
			WritePackCell(packet, RoundIndex)
			WritePackCell(packet, client)
			WritePackCell(packet, RoundFloat(g_eBlocks[7][EffectTime]))
			WritePackString(packet, "Invincibility")
			
			EmitSoundToClient(client, INVI_SOUND_PATH, block)
			CreateTimer(1.0, TimeLeft, packet)
		}
	}
	else if(g_iBlocks[block]==8)
	{
		if(g_bStealthCanUse[client])
		{
			new Handle:packet_f = CreateDataPack()
			WritePackCell(packet_f, RoundIndex)
			WritePackCell(packet_f, client)
			
			CreateTimer(g_eBlocks[8][EffectTime], ResetStealth, packet_f);
			CreateTimer(g_eBlocks[8][CooldownTime], ResetStealthCooldown, packet_f);
			SetEntityRenderMode(client, RENDER_NONE);
			SDKHook(client, SDKHook_SetTransmit, Stealth_SetTransmit)
			g_bStealthCanUse[client]=false;
			
			new Handle:packet = CreateDataPack()
			WritePackCell(packet, RoundIndex)
			WritePackCell(packet, client)
			WritePackCell(packet, RoundFloat(g_eBlocks[8][EffectTime]))
			WritePackString(packet, "Stealth")
			EmitSoundToClient(client, STEALTH_SOUND_PATH, block)
			CreateTimer(1.0, TimeLeft, packet)
		}
	}
	else if(g_iBlocks[block]==11)
	{
		SetEntityGravity(client, 0.4);
		CreateTimer(3.0, ResetGrav, client)
		g_iGravity[client]=1;
	}
	else if(g_iBlocks[block]==12)
	{
		if(IsValidHandle(Block_Timers))
			KillTimer(Block_Timers)
		CreateTimer(g_eBlocks[2][CooldownTime], DamagePlayer_Fire, client);
		IgniteEntity(client, 10000.0);
	}
	else if(g_iBlocks[block]==13)
	{
		CreateTimer(0.0, SlapPlayerBlock, client);
	}
//	else if(g_iBlocks[block]==14)
//	{
//		if(GetClientTeam(client) == 2)
//		{
//			SetEntProp(block_entity, Prop_Data, "m_CollisionGroup", 2);
//		}
//	}
//	else if(g_iBlocks[block]==15)
//	{
//		if(GetClientTeam(client) == 3)
//		{
//			SetEntProp(block_entity, Prop_Data, "m_CollisionGroup", 2);
//		}
//	} 
	else if(g_iBlocks[block]==16)
	{
		if(g_bBootsCanUse[client])
		{
			new Handle:packet_f = CreateDataPack()
			WritePackCell(packet_f, RoundIndex)
			WritePackCell(packet_f, client)
			CreateTimer(g_eBlocks[16][EffectTime], ResetBoots, packet_f);
			CreateTimer(g_eBlocks[16][CooldownTime], ResetBootsCooldown, packet_f);
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 2.33);
			g_bBootsCanUse[client]=false;
			
			new Handle:packet = CreateDataPack()
			WritePackCell(packet, RoundIndex)
			WritePackCell(packet, client)
			WritePackCell(packet, RoundFloat(g_eBlocks[16][EffectTime]))
			WritePackString(packet, "Speed Boost")
			
			EmitSoundToClient(client, BOS_SOUND_PATH, block)
			
			CreateTimer(1.0, TimeLeft, packet)
		}
	}
	else if(g_iBlocks[block]==19)
	{
		g_bNoFallDmg[client]=true;
	}
	else if(g_iBlocks[block]==20)
	{

	}
	else if(g_iBlocks[block]==21)
	{
		if(g_bCamCanUse[client])
		{
			if(GetClientTeam(client)==2)
				SetEntityModel(client, "models/player/ctm_gign.mdl");
			else if(GetClientTeam(client)==3)
				SetEntityModel(client, "models/player/tm_phoenix.mdl");
			g_bCamCanUse[client]=false;
			new Handle:packet_f = CreateDataPack()
			WritePackCell(packet_f, RoundIndex)
			WritePackCell(packet_f, client)
			CreateTimer(g_eBlocks[21][EffectTime], ResetCamouflage, packet_f);
			CreateTimer(g_eBlocks[21][CooldownTime], ResetCamCanUse, packet_f);
			
			new Handle:packet = CreateDataPack()
			WritePackCell(packet, RoundIndex)
			WritePackCell(packet, client)
			WritePackCell(packet, RoundFloat(g_eBlocks[21][EffectTime]))
			WritePackString(packet, "Camouflage")
			EmitSoundToClient(client, CAM_SOUND_PATH, block)
			CreateTimer(1.0, TimeLeft, packet)
		}
	}
	else if(g_iBlocks[block]==22)
	{
		if(g_bDeagleCanUse[client])
		{
			if(GetClientTeam(client)==2)
			{
				new ent = -1;
				if((ent = GetPlayerWeaponSlot(client, 1)) != -1)
					RemovePlayerItem(client, ent);
			//	ent = GivePlayerItem(client, "weapon_deagle");
				ent = Client_GiveWeaponAndAmmo(client, "weapon_deagle", true, 0, 1, 1, 1);
				SetEntProp(ent, Prop_Data, "m_iClip1", 1);
				SetEntProp(ent, Prop_Data, "m_iClip2", 1);
				SetEntData(client, g_iAmmo+(GetEntData(ent, g_iPrimaryAmmoType)<<2), 0, 4, true);
				g_bDeagleCanUse[client] = false;
			}
		}
	}
	else if(g_iBlocks[block]==23)
	{
		if(g_bAwpCanUse[client])
		{
			if(GetClientTeam(client)==2)
			{
				new ent = -1;
				if((ent = GetPlayerWeaponSlot(client, 0)) != -1)
					RemovePlayerItem(client, ent);
			//	ent = GivePlayerItem(client, "weapon_awp");
				ent = Client_GiveWeaponAndAmmo(client, "weapon_awp", true, 0, 1, 1, 1);
				SetEntProp(ent, Prop_Data, "m_iClip1", 1);
				SetEntProp(ent, Prop_Data, "m_iClip2", 1);
				SetEntData(client, g_iAmmo+(GetEntData(ent, g_iPrimaryAmmoType)<<2), 0, 4, true);
				PrintToChatAll("\x03%s\x04 %N has got an AWP, beware CTs!", CHAT_TAG, client);
				g_bAwpCanUse[client] = false;
			}
		}
	}

	// NEW DEATHBLOCK
	else if(g_iBlocks[block]==9)
	{
		if(!g_bInv[client])
			SDKHooks_TakeDamage(client, 0, 0, 10000.0);
	}
	
//	if(bRandom)
//		g_iBlocks[block]=24;
	}
	if(g_iBlocks[block]==1)
	{
		g_bTriggered[block]=true;
		CreateTimer(g_eBlocks[1][EffectTime], StartNoBlock, block);
	}
// 
// OLD DEATHBLOCK
//
//	else if(g_iBlocks[block]==9)
//	{
//		if(!g_bInv[client])
//			SDKHooks_TakeDamage(client, 0, 0, 10000.0);
//	}
	else if(g_iBlocks[block]==18)
	{
		g_bTriggered[block]=true;
		CreateTimer(g_eBlocks[18][EffectTime], StartNoBlock, block);
		SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
	}
	else if(g_iBlocks[block]==28) // Delayed
	{
		g_bTriggered[block]=true;
		CreateTimer(SpeedBoostForce_1[block], StartNoBlock, block);
	}
}

public Action:ResetCooldownRandom(Handle:timer, any:packet)
{
	ResetPack(packet)
	new client = ReadPackCell(packet)
	new round = ReadPackCell(packet)
	if(round == RoundIndex)
	{
		g_bRandomCantUse[client] = false;
		PrintToChat(client, "\x03%s\x04 Random block cooldown has worn off.", CHAT_TAG);
	}
}

public Action:Stealth_SetTransmit(entity, clients)
{
	if(entity == clients)
		return Plugin_Continue;
	return Plugin_Handled;
}

public Action:TimeLeft(Handle:timer, any:pack)
{
	ResetPack(pack)
	new round_index = ReadPackCell(pack)
	if(round_index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}
	new client = ReadPackCell(pack)
	if(!IsFakeClient(client))
	{
		if(IsClientInGame(client))
		{
			new time = ReadPackCell(pack)
			time -= 1
			
			if(time > 0)
			{
				decl String:effectname[32];
				ReadPackString(pack, effectname, sizeof(effectname))
				PrintHintText(client, "%s will worn off in: %i", effectname, time)
				
				new Handle:packet = CreateDataPack()
				WritePackCell(packet, RoundIndex)
				WritePackCell(packet, client)
				WritePackCell(packet, time)
				WritePackString(packet, effectname)
				
				
				CreateTimer(1.0, TimeLeft, packet)
			}
		}
	}
	return Plugin_Continue;
}

public Action:ResetGrav(Handle:timer, any:client)
{
	if(IsValidClient(client))
	{
		SetEntityGravity(client, 1.0)
	}
}

stock bool:IsValidClient(client) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}  

public OnTouch(ent1, ent2)
{
	new client = -1;
	new block = -1;
	if(1 <= ent1 <= MaxClients)
		client = ent1;
	else if(1 <= ent2 <= MaxClients)
		client = ent2;
		
	if(IsValidBlock(ent1))
		block = ent1;
	else if(IsValidBlock(ent2))
		block = ent2;
		
	if(client == -1 || block == -1)
		return;
		
	if(GetClientTeam(client)<2)
		return;
		
	
	decl Float:block_loc[3]
	GetEntPropVector(block, Prop_Send, "m_vecOrigin", block_loc);
	decl Float:player_loc[3]
	GetClientAbsOrigin(client, player_loc)
	player_loc[2] += TrueForce;
	if(!(player_loc[2] <= block_loc[2]))
	{
		
		
	if(g_iBlocks[block]==1)
	{
		if(!g_bTriggered[block])
			CreateTimer(g_eBlocks[1][EffectTime], StartNoBlock, block);
	} else if(g_iBlocks[block]==2)
	{
	} else if(g_iBlocks[block]==3)
	{
	} else if(g_iBlocks[block]==4)
	{
	} else if(g_iBlocks[block]==5)
	{
	} else if(g_iBlocks[block]==6)
	{
	} else if(g_iBlocks[block]==7)
	{
	} else if(g_iBlocks[block]==8)
	{
	} else if(g_iBlocks[block]==9) // DEATHBLOCK
	{
		if(!g_bInv[client])
			SDKHooks_TakeDamage(client, 0, 0, 10000.0);
	} else if(g_iBlocks[block]==10)
	{
	} else if(g_iBlocks[block]==11)
	{
	} else if(g_iBlocks[block]==12)
	{
	} else if(g_iBlocks[block]==13)
	{
	} else if(g_iBlocks[block]==14)
	{
	} else if(g_iBlocks[block]==15)
	{
	} else if(g_iBlocks[block]==16)
	{
	} else if(g_iBlocks[block]==18)
	{
		if(!g_bTriggered[block])
			CreateTimer(g_eBlocks[18][EffectTime], StartNoBlock, block);
		SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
	} 
	else if(g_iBlocks[block]==19)
	{
		g_bNoFallDmg[client]=true;
	}
	else if(g_iBlocks[block] == 20)
	{
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.3);
	}
	else if(g_iBlocks[block]==25)
	{
		if(g_bHEgrenadeCanUse[client])
		{
			if(GetClientTeam(client) == 2)
			{
				if(GetClientHEGrenades(client) < 1)
				{
					GivePlayerItem(client, "weapon_hegrenade");
					g_bHEgrenadeCanUse[client] = false;
				}
			}
		}
	}
	else if(g_iBlocks[block]==26)
	{
		if(g_bFlashbangCanUse[client])
		{
			if(GetClientTeam(client)==2)
			{
				if(GetClientFlashbangs(client) < 1)
				{
					GivePlayerItem(client, "weapon_flashbang");
					g_bFlashbangCanUse[client] = false;
				}
			}
		}
	} 
	else if(g_iBlocks[block]==27)
	{
		if(g_bSmokegrenadeCanUse[client])
		{
			if(GetClientTeam(client) == 2)
			{
				if(GetClientSmokeGrenades(client) < 1)
				{
					// GivePlayerItem(client, "weapon_smokegrenade");
					GivePlayerItem(client, "weapon_decoy");
					g_bSmokegrenadeCanUse[client] = false;
				}
			}
		}
	}
	
//	if(bRandom)
//		g_iBlocks[block]=24;
	}
	Block_Touching[client] = g_iBlocks[block]
}

// Thanks for those three stocks to TnTSCS (https://forums.alliedmods.net/showpost.php?p=2242491&postcount=12)

stock GetClientHEGrenades(client) 
{
    return GetEntProp(client, Prop_Data, "m_iAmmo", _, HEGrenadeOffset);
}

stock GetClientSmokeGrenades(client)
{
    return GetEntProp(client, Prop_Data, "m_iAmmo", _, SmokegrenadeOffset);
}

stock GetClientFlashbangs(client)
{
    return GetEntProp(client, Prop_Data, "m_iAmmo", _, FlashbangOffset);
}

public OnEndTouch(ent1, ent2)
{
	new client = -1;
	new block = -1;
	if(1 <= ent1 <= MaxClients)
		client = ent1;
	else if(1 <= ent2 <= MaxClients)
		client = ent2;
		
	if(IsValidBlock(ent1))
		block = ent1;
	else if(IsValidBlock(ent2))
		block = ent2;
		
	if(client == -1 || block == -1)
		return;
		
	if(GetClientTeam(client)<2)
		return;
		
	decl Float:block_loc[3]
	GetEntPropVector(block, Prop_Send, "m_vecOrigin", block_loc);
	
	decl Float:player_loc[3]
	GetClientAbsOrigin(client, player_loc)
	
	player_loc[2] += TrueForce;
	if(!(player_loc[2] <= block_loc[2]))
	{
			
		if(g_iBlocks[block]==1)
		{
		} else if(g_iBlocks[block]==2)
		{
		} else if(g_iBlocks[block]==3)
		{
		} else if(g_iBlocks[block]==4)
		{
		} else if(g_iBlocks[block]==5)
		{
			g_bNoFallDmg[client]=false;
		} else if(g_iBlocks[block]==6)
		{
		} else if(g_iBlocks[block]==7)
		{
		} else if(g_iBlocks[block]==8)
		{
		} else if(g_iBlocks[block]==9)
		{
		} else if(g_iBlocks[block]==10)
		{
		} else if(g_iBlocks[block]==11)
		{
			g_iGravity[client]=2;
		} else if(g_iBlocks[block]==12)
		{
			CreateTimer(0.2, ResetFire, client)

		} else if(g_iBlocks[block]==13)
		{
		} else if(g_iBlocks[block]==14)
		{
		} else if(g_iBlocks[block]==15)
		{
		} else if(g_iBlocks[block]==16)
		{
		} else if(g_iBlocks[block]==18)
		{
		} else if(g_iBlocks[block]==19)
		{
			g_bNoFallDmg[client]=false;
		}
		else if(g_iBlocks[block]==20)
		{
			CreateTimer(0.2, ResetHoney, client)
		}
		
//		if(bRandom)
//		{
//			g_iBlocks[block]=24;
//		}
	}
	CreateTimer(0.01, BlockTouch_End, client)
}

public Action:ResetFire(Handle:timer, any:client)
{
	if(Block_Touching[client] != 12)
	{
		new ent = GetEntPropEnt(client, Prop_Data, "m_hEffectEntity");
		if (IsValidEdict(ent))
			SetEntPropFloat(ent, Prop_Data, "m_flLifetime", 0.0);
	}
}

public Action:BlockTouch_End(Handle:timer, any:client)
{
	Block_Touching[client] = 0;
}

public Action:ResetHoney(Handle:timer, any:client)
{
	if(Block_Touching[client] != 20)
	{
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	}
}

public Action:DamagePlayer(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		if(IsPlayerAlive(client))
		{
			if(Block_Touching[client] == 2)
			{
				if(GetClientHealth(client)-5>0)
					SetEntityHealth(client, GetClientHealth(client)-5);
				else
					SlapPlayer(client, 10);
				Block_Timers = CreateTimer(g_eBlocks[3][EffectTime], DamagePlayer, client);
			}
		}
	} 
	return Plugin_Stop; 
}

public Action:DamagePlayer_Fire(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		if(IsPlayerAlive(client))
		{
			if(Block_Touching[client] == 12)
			{
				SDKHooks_TakeDamage(client, 0, 0, float(RoundFloat(GetRandomFloat(1.00, 8.00))), DMG_BURN)
				Block_Timers = CreateTimer(g_eBlocks[2][EffectTime], DamagePlayer_Fire, client);
			}
		}
	} 
	return Plugin_Stop;
}

public Action:ResetCamouflage(Handle:timer, any:packet)
{
	ResetPack(packet)
	new index = ReadPackCell(packet)
	if(index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}
	new client = ReadPackCell(packet)
	
	if(!IsClientInGame(client))
		return Plugin_Stop;
	if(GetClientTeam(client)==3)
		SetEntityModel(client, "models/player/ctm_gign.mdl");
	else if(GetClientTeam(client)==2)
		SetEntityModel(client, "models/player/tm_phoenix.mdl");
		
	PrintToChat(client, "\x03%s\x04 Camouflage has worn off.", CHAT_TAG);
	return Plugin_Stop;
}

public Action:ResetCamCanUse(Handle:timer, any:packet)
{
	ResetPack(packet)
	new index = ReadPackCell(packet)
	if(index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}
	new client = ReadPackCell(packet)
	
	if(!IsClientInGame(client))
		return Plugin_Stop;
	g_bCamCanUse[client]=true;
	PrintToChat(client, "\x03%s\x04 Camouflage block cooldown has worn off.", CHAT_TAG);
	return Plugin_Stop;
}

public Action:StartNoBlock(Handle:timer, any:block)
{
	SetEntProp(block, Prop_Data, "m_CollisionGroup", 2);
	SetEntityRenderMode(block, RENDER_TRANSADD);
	if(Block_Transparency[block] > 0)
	{
		SetEntityRenderColor(block, 177, 177, 177, RoundFloat(float(Block_Transparency[block])*0.4588));
	}
	else
	{
		SetEntityRenderColor(block, 177, 177, 177, 177);
	}
	CreateTimer(g_eBlocks[g_iBlocks[block]][CooldownTime], CancelNoBlock, block);
	return Plugin_Stop;
}

public Action:CancelNoBlock(Handle:timer, any:block)
{
	SetEntProp(block, Prop_Data, "m_CollisionGroup", 0);
	SetEntityRenderMode(block, RENDER_TRANSCOLOR); 
	if(Block_Transparency[block] > 0)
	{
		SetEntityRenderColor(block, 255, 255, 255, Block_Transparency[block]);
	}
	else
	{
		SetEntityRenderColor(block, 255, 255, 255, 255);
	}
	g_bTriggered[block]=false;
	return Plugin_Stop;
}

public Action:HealPlayer(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		if(IsPlayerAlive(client))
		{
			if(Block_Touching[client] == 3)
			{
				if(GetClientHealth(client)+5<=100)
					SetEntityHealth(client, GetClientHealth(client)+5);
				else
					SetEntityHealth(client, 100);
				Block_Timers = CreateTimer(g_eBlocks[3][EffectTime], HealPlayer, client);
			}
		}
	}
	return Plugin_Stop;
}

public Action:ResetNoFall(Handle:timer, any:client)
{
	if(!IsClientInGame(client))
		return Plugin_Stop;
	g_bNoFallDmg[client] = false;
	return Plugin_Stop;
}

public Action:ResetInv(Handle:timer, any:packet)
{
	ResetPack(packet)
	new index = ReadPackCell(packet)
	if(index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}
	new client = ReadPackCell(packet)
	if(!IsClientInGame(client))
		return Plugin_Stop;
	g_bInv[client] = false;
	PrintToChat(client, "\x03%s\x04 Invincibility has worn off.", CHAT_TAG);
	return Plugin_Stop;
}

public Action:ResetInvCooldown(Handle:timer, any:packet)
{
	ResetPack(packet)
	new index = ReadPackCell(packet)
	if(index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}
	new client = ReadPackCell(packet)
	if(!IsClientInGame(client))
		return Plugin_Stop;
	g_bInvCanUse[client] = true;
	PrintToChat(client, "\x03%s\x04 Invincibility block cooldown has worn off.", CHAT_TAG);
	return Plugin_Stop;
}

public Action:ResetStealth(Handle:timer, any:packet)
{
	ResetPack(packet)

	new index = ReadPackCell(packet)

	if(index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}

	new client = ReadPackCell(packet) 
	
	if(!IsClientInGame(client))
		return Plugin_Stop;
	SetEntityRenderMode(client , RENDER_NORMAL); 
	SDKUnhook(client, SDKHook_SetTransmit, Stealth_SetTransmit)
	PrintToChat(client, "\x03%s\x04 Stealth has worn off.", CHAT_TAG);
	return Plugin_Stop;
}

public Action:ResetStealthCooldown(Handle:timer, any:packet)
{
	ResetPack(packet)
	new index = ReadPackCell(packet)
	if(index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}
	new client = ReadPackCell(packet)
	if(!IsClientInGame(client))
		return Plugin_Stop;
	g_bStealthCanUse[client] = true;
	PrintToChat(client, "\x03%s\x04 Stealth block cooldown has worn off.", CHAT_TAG);
	return Plugin_Stop;
}

//public Action:ResetRandom(Handle:timer, any:packet)
//{
//	ResetPack(packet)
//	new index = ReadPackCell(packet)
//	if(index != RoundIndex)
//	{
//		KillTimer(timer, true)
//		return Plugin_Handled;
//	}
//	new client = ReadPackCell(packet)
//
//	if(!IsClientInGame(client))
//		return Plugin_Stop;
//	g_iClientBlocks[client]=-1;
//	return Plugin_Stop;
//}

public Action:ResetBoots(Handle:timer, any:packet)
{
	ResetPack(packet)
	new index = ReadPackCell(packet)
	if(index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}
	new client = ReadPackCell(packet)
	
	if(!IsClientInGame(client))
		return Plugin_Stop;
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	PrintToChat(client, "\x03%s\x04 Boots of Speed has worn off.", CHAT_TAG);
	return Plugin_Stop;
}

public Action:ResetBootsCooldown(Handle:timer, any:packet)
{
	ResetPack(packet)
	new index = ReadPackCell(packet)
	if(index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}
	new client = ReadPackCell(packet)
	
	if(!IsClientInGame(client))
		return Plugin_Stop;
	
	g_bBootsCanUse[client] = true;
	PrintToChat(client, "\x03%s\x04 Boots of Speed block cooldown has worn off.", CHAT_TAG);
	return Plugin_Stop;
}

public ShowMenuDelayed_NoSlowdown(client)
{
	new Handle:menu = CreateMenu(MenuDelayed_Return, MenuAction_Select | MenuAction_End);
	SetMenuTitle(menu, "Choose Delay for disappearance of the block:");
	AddMenuItem(menu, "0.01", "0.01s")
	AddMenuItem(menu, "0.02", "0.02s")
	AddMenuItem(menu, "0.03", "0.03s")
	AddMenuItem(menu, "0.04", "0.04s")
	AddMenuItem(menu, "0.05", "0.05s")
	AddMenuItem(menu, "0.10", "0.10s")
	AddMenuItem(menu, "0.15", "0.15s")
	AddMenuItem(menu, "0.20", "0.20s")
	AddMenuItem(menu, "0.25", "0.25s")
	AddMenuItem(menu, "0.30", "0.30s")
	AddMenuItem(menu, "0.35", "0.35s")
	AddMenuItem(menu, "0.40", "0.40s")
	AddMenuItem(menu, "0.45", "0.45s")
	AddMenuItem(menu, "0.50", "0.50s")
	AddMenuItem(menu, "0.60", "0.60s")
	AddMenuItem(menu, "0.70", "0.70s")
	AddMenuItem(menu, "0.80", "0.80s")
	AddMenuItem(menu, "0.90", "0.90s")
	AddMenuItem(menu, "1", "1s")

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}


public Action:ShowMenuDelayed_NoSlowdown2(Handle:timer, any:client)
{
	new Handle:menu = CreateMenu(MenuDelayed_Return2, MenuAction_Select | MenuAction_End);
	SetMenuTitle(menu, "Choose Delay for disappearance of the block:");
	AddMenuItem(menu, "0.01", "0.01s")
	AddMenuItem(menu, "0.02", "0.02s")
	AddMenuItem(menu, "0.03", "0.03s")
	AddMenuItem(menu, "0.04", "0.04s")
	AddMenuItem(menu, "0.05", "0.05s")
	AddMenuItem(menu, "0.10", "0.10s")
	AddMenuItem(menu, "0.15", "0.15s")
	AddMenuItem(menu, "0.20", "0.20s")
	AddMenuItem(menu, "0.25", "0.25s")
	AddMenuItem(menu, "0.30", "0.30s")
	AddMenuItem(menu, "0.35", "0.35s")
	AddMenuItem(menu, "0.40", "0.40s")
	AddMenuItem(menu, "0.45", "0.45s")
	AddMenuItem(menu, "0.50", "0.50s")
	AddMenuItem(menu, "0.60", "0.60s")
	AddMenuItem(menu, "0.70", "0.70s")
	AddMenuItem(menu, "0.80", "0.80s")
	AddMenuItem(menu, "0.90", "0.90s")
	AddMenuItem(menu, "1", "1s")

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

 public ShowMenuDelayed(client)
{
		new Handle:menu = CreateMenu(MenuDelayed_Return, MenuAction_Select | MenuAction_End);
		SetMenuTitle(menu, "Choose Delay for disappearance of the block:");
		AddMenuItem(menu, "0.25", "0.25s")
		AddMenuItem(menu, "0.5", "0.5s")
		AddMenuItem(menu, "0.75", "0.75s")
		AddMenuItem(menu, "1", "1s")
		AddMenuItem(menu, "1.5", "1.5s")
		AddMenuItem(menu, "2", "2s")
		AddMenuItem(menu, "2.5", "2.5s")
		AddMenuItem(menu, "3.0", "3s")
		AddMenuItem(menu, "3.5", "3.5s")
		AddMenuItem(menu, "4.0", "4s")
		AddMenuItem(menu, "4.5", "4.5s")
		AddMenuItem(menu, "5.0", "5s")
		AddMenuItem(menu, "6", "6s")
		AddMenuItem(menu, "7", "7s")
		AddMenuItem(menu, "8", "8s")
		AddMenuItem(menu, "9", "9s")
		AddMenuItem(menu, "10", "10s")

		DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

 public Action:ShowMenuDelayed2(Handle:timer, any:client)
{
		new Handle:menu = CreateMenu(MenuDelayed_Return2, MenuAction_Select | MenuAction_End);
		SetMenuTitle(menu, "Choose Delay for disappearance of the block:");
		AddMenuItem(menu, "0.25", "0.25s")
		AddMenuItem(menu, "0.5", "0.5s")
		AddMenuItem(menu, "0.75", "0.75s")
		AddMenuItem(menu, "1", "1s")
		AddMenuItem(menu, "1.5", "1.5s")
		AddMenuItem(menu, "2", "2s")
		AddMenuItem(menu, "2.5", "2.5s")
		AddMenuItem(menu, "3.0", "3s")
		AddMenuItem(menu, "3.5", "3.5s")
		AddMenuItem(menu, "4.0", "4s")
		AddMenuItem(menu, "4.5", "4.5s")
		AddMenuItem(menu, "5.0", "5s")
		AddMenuItem(menu, "6", "6s")
		AddMenuItem(menu, "7", "7s")
		AddMenuItem(menu, "8", "8s")
		AddMenuItem(menu, "9", "9s")
		AddMenuItem(menu, "10", "10s")

		DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuDelayed_Return2(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[16];
			GetMenuItem(menu, param2, item, sizeof(item));
			SpeedBoostForce_1[CurrentModifier[client]] = StringToFloat(item)
			
			SDKHook(CurrentModifier[client], SDKHook_StartTouch, OnStartTouch);
			SDKHook(CurrentModifier[client], SDKHook_Touch, OnTouch);
			SDKHook(CurrentModifier[client], SDKHook_EndTouch, OnEndTouch);
			DisplayMenu(CreateMainMenu(client), client, 0);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}
public MenuDelayed_Return(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[16];
			GetMenuItem(menu, param2, item, sizeof(item));
			SpeedBoostForce_1[CurrentModifier[client]] = StringToFloat(item)

			DisplayMenu(CreateMainMenu(client), client, 0);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

 public ShowMenu3E(client)
{
		new Handle:menu = CreateMenu(TFCH_BoostF, MenuAction_Select | MenuAction_End);
		SetMenuTitle(menu, "Choose Speed Boost Forward Force:");
		AddMenuItem(menu, "1000", "1000");
		AddMenuItem(menu, "900", "900");
		AddMenuItem(menu, "800", "800 (DEFAULT)");
		AddMenuItem(menu, "700", "700");
		AddMenuItem(menu, "600", "600");
		AddMenuItem(menu, "500", "500");
		AddMenuItem(menu, "400", "400");
		AddMenuItem(menu, "300", "300");
		AddMenuItem(menu, "200", "200");

		DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
 public Action:ShowMenu3(Handle:timer, any:client)
{
		new Handle:menu = CreateMenu(TFCH_BoostF, MenuAction_Select | MenuAction_End);
		SetMenuTitle(menu, "Choose Speed Boost Forward Force:");
		AddMenuItem(menu, "1000", "1000");
		AddMenuItem(menu, "900", "900");
		AddMenuItem(menu, "800", "800 (DEFAULT)");
		AddMenuItem(menu, "700", "700");
		AddMenuItem(menu, "600", "600");
		AddMenuItem(menu, "500", "500");
		AddMenuItem(menu, "400", "400");
		AddMenuItem(menu, "300", "300");
		AddMenuItem(menu, "200", "200");

		DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public TFCH_BoostF(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[16];
			GetMenuItem(menu, param2, item, sizeof(item));
			SpeedBoostForce_1[CurrentModifier[client]] = StringToFloat(item)
			
			SDKHook(CurrentModifier[client], SDKHook_StartTouch, OnStartTouch);
			SDKHook(CurrentModifier[client], SDKHook_Touch, OnTouch);
			SDKHook(CurrentModifier[client], SDKHook_EndTouch, OnEndTouch);
			ShowMenu4(client)
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public TFCH_BoostF2(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[16];
			GetMenuItem(menu, param2, item, sizeof(item));
			SpeedBoostForce_2[CurrentModifier[client]] = StringToFloat(item)
			DisplayMenu(CreateMainMenu(client), client, 0);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

 public ShowMenu4(client)
{
		new Handle:menu = CreateMenu(TFCH_BoostF2, MenuAction_Select | MenuAction_End);
		SetMenuTitle(menu, "Choose Speed Boost Jump Force:");
		AddMenuItem(menu, "1000", "1000");
		AddMenuItem(menu, "900", "900");
		AddMenuItem(menu, "800", "800");
		AddMenuItem(menu, "700", "700");
		AddMenuItem(menu, "600", "600");
		AddMenuItem(menu, "500", "500");
		AddMenuItem(menu, "400", "400");
		AddMenuItem(menu, "300", "300");
		AddMenuItem(menu, "260", "260 (DEFAULT)");
		AddMenuItem(menu, "200", "200");

		DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public Action:BoostPlayer(Handle:timer, any:pack)
{
	ResetPack(pack)
	new client = ReadPackCell(pack)
	new block = ReadPackCell(pack)
	
	new Float:fAngles[3];
	GetClientEyeAngles(client, fAngles);
	
	new Float:fVelocity[3];
	GetAngleVectors(fAngles, fVelocity, NULL_VECTOR, NULL_VECTOR);
	
	NormalizeVector(fVelocity, fVelocity);
	
	ScaleVector(fVelocity, SpeedBoostForce_1[block]);
	fVelocity[2] = SpeedBoostForce_2[block];
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
	return Plugin_Stop;
}

public Action:JumpPlayer(Handle:timer, any:pack)
{
	ResetPack(pack)
	new client = ReadPackCell(pack)
	new block = ReadPackCell(pack)
	if(IsClientInGame(client) && IsValidBlock(block))
	{
		decl Float:block_loc[3]
		GetEntPropVector(block, Prop_Send, "m_vecOrigin", block_loc);
		decl Float:player_loc[3]
		GetClientAbsOrigin(client, player_loc)
		player_loc[2] += TrueForce;
		if(!(player_loc[2] <= block_loc[2]))
		{
			new Float:fVelocity[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
			fVelocity[0]*=1.5;
			fVelocity[1]*=1.5;
			fVelocity[2] = TrampolineForce[block]
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
		}
		else
		{
			new Float:fVelocity[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
			fVelocity[0]*=1.25;
			fVelocity[1]*=1.25;
			fVelocity[2] = 300.0
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
		}
	}
	return Plugin_Stop;
}

public Action:SlapPlayerBlock(Handle:timer, any:client)
{
	SlapPlayer(client, 5);
	new Float:fVelocity[3];
	fVelocity[0] = float(GetRandomInt(-100, 100));
	fVelocity[1] = float(GetRandomInt(-100, 100));
	fVelocity[2] = float(GetRandomInt(260, 360));
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
	return Plugin_Stop;
}

public Handler_Teleport(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		if(param2==0)
		{
			if(g_iCurrentTele[client]==-1)
				CreateTeleportEntrance(client);
			else
			{
				if(IsValidEdict(g_iCurrentTele[client]))
					AcceptEntityInput(g_iCurrentTele[client], "Kill");
				g_iCurrentTele[client]=-1;
			}
		} else if(param2==1)
		{
			if(g_iCurrentTele[client]==-1)
				PrintToChat(client, "\x03%s\x04 You must create an entrance first", CHAT_TAG);
			else
			{
				g_iTeleporters[g_iCurrentTele[client]]=CreateTeleportExit(client);
				g_iCurrentTele[client]=-1;
			}
		} else if(param2==2)
		{
			new ent = GetClientAimTarget(client, false);
			new entrance = -1;
			new hexit = -1;
			if(g_iTeleporters[ent]>=1)
			{
				if(g_iTeleporters[ent]>1)
				{
					entrance = ent;
					hexit = g_iTeleporters[ent];
				}
				else
				{
				    for(new i=MaxClients+1;i<2048;++i)
					{
						if(g_iTeleporters[i]==ent)
						{
							hexit = ent;
							entrance = i;
							break;
						}
					}
				}
				
				if(entrance > 0 && hexit > 0)
				{
					if(IsValidBlock(entrance) && IsValidBlock(hexit))
					{
						SetEntityModel(entrance, "models/blockbuilder/tele_end.mdl");
						SetEntityModel(hexit, "models/blockbuilder/tele_start.mdl");
						g_iTeleporters[entrance]=1;
						g_iTeleporters[hexit]=entrance;
					}
				}
			}
		} else if(param2==3)
		{
			new ent = GetClientAimTarget(client, false);
			if(IsValidBlock(ent))
			{
				AcceptEntityInput(ent, "Kill");
				g_iBlocks[ent]=-1;
				if(g_iTeleporters[ent]>=1)
				{
					if(g_iTeleporters[ent]>1 && IsValidBlock(g_iTeleporters[ent]))
					{
						AcceptEntityInput(g_iTeleporters[ent], "Kill");
						g_iTeleporters[g_iTeleporters[ent]] = -1;
					} else if(g_iTeleporters[ent]==1)
					{
						for(new i=MaxClients+1;i<2048;++i)
						{
							if(g_iTeleporters[i]==ent)
							{
								if(IsValidBlock(i))
									AcceptEntityInput(i, "Kill");
								g_iTeleporters[i] = -1;
								break;
							}
						}
					}
					
					g_iTeleporters[ent]=-1;
				}
			}
		} else if(param2==4)
		{
			new ent = GetClientAimTarget(client, false);
			if(ent!=-1)
			{
				new entrance = -1;
				new hexit = -1;
				if(g_iTeleporters[ent]>=1)
				{
					if(g_iTeleporters[ent]>1)
					{
						entrance = ent;
						hexit = g_iTeleporters[ent];
					}
					else
					{
						for(new i=MaxClients+1;i<2048;++i)
						{
							if(g_iTeleporters[i]==ent)
							{
								hexit = ent;
								entrance = i;
								break;
							}
						}
					}
					if(entrance > 0 && hexit > 0)
					{
						if(IsValidBlock(entrance) && IsValidBlock(hexit))
						{
							new color[4]={255, 0, 0, 255};
							new Float:pos1[3], Float:pos2[3];
							GetEntPropVector(entrance, Prop_Data, "m_vecOrigin", pos1);
							GetEntPropVector(hexit, Prop_Data, "m_vecOrigin", pos2);
							TE_SetupBeamPoints(pos2, pos1, g_iBeamSprite, 0, 0, 40, 15.0, 20.0, 20.0, 25, 0.0, color, 10);
							TE_SendToClient(client);
						}
					}
				}
			}
			else
			{
				PrintToChat(client, "\x03%s\x04 You must aim at a teleporter first", CHAT_TAG);
			}
		}
		DisplayMenu(CreateTeleportMenu(client), client, 0);
	}
	else if ((action == MenuAction_Cancel) && (param2 == MenuCancel_ExitBack))
		DisplayMenu(CreateMainMenu(client), client, 0);
}

public Handler_Blocks(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		g_iBlockSelection[client]=param2;
		//PrintToChat(client, "%sYou have selected block \x03%s\x04.", CHAT_TAG, g_eBlocks[param2][BlockName]);
		DisplayMenu(CreateMainMenu(client), client, 0);
	}
	else if ((action == MenuAction_Cancel) && (param2 == MenuCancel_ExitBack))
		DisplayMenu(CreateMainMenu(client), client, 0);
}

public Handler_Options(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new bool:bDontDisplay = false;
		if(param2 == 0)
		{
			if(g_bSnapping[client])
				g_bSnapping[client]=false;
			else
				g_bSnapping[client]=true;
		}
		else if(param2 == 1)
		{
			if(g_fSnappingGap[client]<100.0)
				g_fSnappingGap[client]+=5.0;
			else
				g_fSnappingGap[client]=0.0;
		}
		else if(param2 == 2)
		{
			new ent = GetClientAimTarget(client, false);
			if(IsValidBlock(ent))
				g_bGroups[client][ent]=true;
		} else if(param2 == 3)
		{
			for(new i=0;i<2048;++i)
				g_bGroups[client][i] = false;
		} else if(param2 == 4)
		{
			LoadBlocks_Menu(client);
			bDontDisplay = true;
		} else if(param2 == 5)
		{
			SaveBlocks_Menu(client);
			bDontDisplay = true;
		} else if(param2 == 6)
		{
			for(new i=MaxClients+1;i<2048;++i)
			{
				if(g_iBlocks[i]!=-1)
				{
					if(IsValidBlock(i))
					{
						AcceptEntityInput(i, "Kill");
					}
					g_iBlocks[i]=-1;
				}
			}
		} else if(param2 == 7)
		{
			for(new i=MaxClients+1;i<2048;++i)
			{
				if(g_iTeleporters[i]!=-1)
				{
					if(IsValidBlock(i))
					{
						AcceptEntityInput(i, "Kill");
					}
					g_iTeleporters[i]=-1;
				}
			}
		}
		if(!bDontDisplay)
		{
			DisplayMenu(CreateOptionsMenu(client), client, 0);
		}
	}
	else if ((action == MenuAction_Cancel) && (param2 == MenuCancel_ExitBack))
		DisplayMenu(CreateMainMenu(client), client, 0);
}

stock SaveBlocks_Menu(client)
{
	new Handle:menu = CreateMenu(SaveBlocks_Handler, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
	SetMenuTitle(menu, "Block Builder - Save Blocks?");
	AddMenuItem(menu, "X", "Are you sure you want to save blocks?", ITEMDRAW_DISABLED)
	AddMenuItem(menu, "1", "Yes!")
	AddMenuItem(menu, "2", "No!")
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public SaveBlocks_Handler(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			
			new option = StringToInt(item)
			if(option == 1)
			{
				SaveBlocks(true)
			}
			else
			{
				DisplayMenu(CreateOptionsMenu(client), client, 0);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}


stock LoadBlocks_Menu(client)
{
	new Handle:menu = CreateMenu(LoadBlocks_Handler, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
	SetMenuTitle(menu, "Block Builder - Load Blocks?");
	AddMenuItem(menu, "X", "Are you sure you want to load blocks?", ITEMDRAW_DISABLED)
	AddMenuItem(menu, "1", "Yes!")
	AddMenuItem(menu, "2", "No!")
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
} 

public LoadBlocks_Handler(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			
			new option = StringToInt(item)
			if(option == 1)
			{
				LoadBlocks(true)
			}
			else
			{
				DisplayMenu(CreateOptionsMenu(client), client, 0);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

bool:IsValidBlock(ent)
{
	if(MaxClients < ent < 2048)
		if((g_iBlocks[ent] != -1 || g_iTeleporters[ent]!=-1) && IsValidEdict(ent))
			return true;
	return false;
}

stock FakePrecacheSound( const String:szPath[] )
{
	AddToStringTable( FindStringTable( "soundprecache" ), szPath );
}

stock GetCurrentWorkshopMap(String:szMap[], iMapBuf, String:szWorkShopID[], iWorkShopBuf)
{
    decl String:szCurMap[128];
    decl String:szCurMapSplit[2][64];
    
    GetCurrentMap(szCurMap, sizeof(szCurMap));
    
    ReplaceString(szCurMap, sizeof(szCurMap), "workshop/", "", false);
    
    ExplodeString(szCurMap, "/", szCurMapSplit, 2, 64);
    
    strcopy(szMap, iMapBuf, szCurMapSplit[1]);
    strcopy(szWorkShopID, iWorkShopBuf, szCurMapSplit[0]);
}