#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <colors>

#tryinclude "ztf2grab"

#define MP 34
#define ME 2048

#define PLUGIN_VERSION "2.4"

new g_BeamSprite;
new g_HaloSprite;

new bool:UseAmplifier[MP]=false;
new bool:UseRepairNode[MP]=false;
new bool:DontAsk[MP]=false;
new bool:NearAmplifier[MP]=false;
new bool:AmplifierOn[ME]=false;
new bool:AmplifierSapped[ME]=false;
new bool:ConditionApplied[ME][MP];
new Float:AmplifierDistance[ME];
new TFCond:AmplifierCondition[ME];
new AmplifierPercent[ME];
new BuildingRef[ME];
new EngiAssists[MP]=0;
new GetPar[MP];

new Handle:cvarMetal = INVALID_HANDLE;
new Handle:cvarMetalMax = INVALID_HANDLE;
new Handle:cvarRegeneration = INVALID_HANDLE;
new Handle:cvarDistance = INVALID_HANDLE;
new Handle:cvarCondition = INVALID_HANDLE;
new Handle:cvarParticle = INVALID_HANDLE;
new Handle:cvarPercent = INVALID_HANDLE;
new Handle:cvarWallBlock = INVALID_HANDLE;
new Handle:cvarMiniCritToSG = INVALID_HANDLE;
new Handle:cvarAnnounce = INVALID_HANDLE;
new Handle:cvarNode = INVALID_HANDLE;

new Handle:fwdOnAmplify = INVALID_HANDLE;

new TFCond:DefaultCondition = TFCond_Kritzkrieged;
new Float:DefaultDistance = 200.0;
new bool:MiniCritToSG = true;
new bool:ShowParticle = true;
new bool:WallBlock = false;
new bool:Node = false;
new DefaultPercent = 100;

new MetalRegeneration = 10;
new MetalPerPlayer = 5;
new MetalMax = 400;
new Revenges[MP]=0;				//for Engineers with Frontier Justice

new bool:NativeControl = false;
new TFCond:NativeCondition[MP];
new Float:NativeDistance[MP];
new NativePercent[MP];

#define AmplifierModel "models/buildables/amplifier_test/amplifier"
#define AmplifierTex "materials/models/buildables/amplifier_test/amplifier"
#define AMPgib "models/buildables/amplifier_test/gibs/amp_gib"

public Plugin:myinfo = {
	name = "The Amplifier",
	author = "RainBolt Dash (plugin); Jumento M.D. (idea & model); Naris and FlaminSarge (helpers)",
	description = "Adds The Amplifier (crit dispenser)",
	version = PLUGIN_VERSION,
};

/**
 * Description: Stocks to return information about TF2 player condition, etc.
 */
#tryinclude <tf2_player>
#if !defined _tf2_player_included
    #define TF2_IsDisguised(%1)         (((%1) & TF_CONDFLAG_DISGUISED) != TF_CONDFLAG_NONE)
    #define TF2_IsCloaked(%1)           (((%1) & TF_CONDFLAG_CLOAKED) != TF_CONDFLAG_NONE)
#endif

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	// Register Natives
	CreateNative("ControlAmplifier",Native_ControlAmplifier);
	CreateNative("SetAmplifier",Native_SetAmplifier);
	CreateNative("HasAmplifier",Native_HasAmplifier);
	CreateNative("ConvertToAmplifier",Native_ConvertToAmplifier);

	fwdOnAmplify=CreateGlobalForward("OnAmplify",ET_Hook,Param_Cell,Param_Cell,Param_Cell);

	RegPluginLibrary("Amplifier");
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("amplifier_version", PLUGIN_VERSION, "The Amplifier Version", FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarParticle = CreateConVar("amplifier_particle", "1", "Enable the Buffed Particle.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarCondition = CreateConVar("amplifier_condition", "33", "Condition that The amplifier dispenses (11=full crits, 16=mini crits, etc...).", FCVAR_PLUGIN);
	cvarPercent = CreateConVar("amplifier_percent", "100.0", "Percent chance of the amplifier applying the condition.", FCVAR_PLUGIN, true, 0.0, true, 100.0);
	cvarDistance = CreateConVar("amplifier_distance", "200.0", "Distance the amplifier works.", FCVAR_PLUGIN);
	cvarRegeneration = CreateConVar("amplifier_regeneration", "15.0", "Amount of metal to regenerate per second.", FCVAR_PLUGIN);
	cvarMetalMax = CreateConVar("amplifier_max", "400.0", "Maximum amount of metal an amplifier can hold.", FCVAR_PLUGIN);
	cvarMetal = CreateConVar("amplifier_metal", "5.0", "Amount of metal to use to apply a condition to a player (per second).", FCVAR_PLUGIN);
	cvarWallBlock = CreateConVar("amplifier_wallblock", "0", "Teammates can (0) or can not (1) get crits through walls, players, props etc", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarMiniCritToSG = CreateConVar("amplifier_sg_wrangler_mini-crit", "1", "Controlled (by Wrangler) SentryGun will get mini-crits, if engineer near AMP", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarAnnounce = CreateConVar("amplifier_Announce", "150", "Info about AMP will show every N seconds", FCVAR_PLUGIN);
	cvarNode = CreateConVar("amplifier_and_repairnode", "0", "Allow use Repair Node and AMP on 1 server without conflicts", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	HookEvent("player_builtobject", Event_Build);
	CreateTimer(1.0, Timer_amplifier, _, TIMER_REPEAT);
	//HookEvent("teamplay_round_start", event_RoundStart);
	HookEvent("player_spawn", Event_player_spawn);
	//HookEntityOutput("obj_dispenser", "OnObjectHealthChanged", objectHealthChanged);
	RegConsoleCmd("amplifier",        CallPanel, "Select 2nd engineer's building ");
	RegConsoleCmd("amp",        CallPanel, "Select 2nd engineer's building ");
	RegConsoleCmd("amp_help",        HelpPanel, "Show info about Amplifier");

	AddToDownload();
	LoadTranslations("Amplifier");
	HookEvent("player_death", event_player_death);

	HookConVarChange(cvarRegeneration, CvarChange);
	HookConVarChange(cvarMiniCritToSG, CvarChange);
	HookConVarChange(cvarWallBlock, CvarChange);
	HookConVarChange(cvarCondition, CvarChange);
	HookConVarChange(cvarParticle, CvarChange);
	HookConVarChange(cvarDistance, CvarChange);
	HookConVarChange(cvarMetalMax, CvarChange);
	HookConVarChange(cvarPercent, CvarChange);
	HookConVarChange(cvarMetal, CvarChange);
	HookConVarChange(cvarNode, CvarChange);
	
	//Fix conflicts with Repair Node (http://forums.alliedmods.net/showthread.php?p=1234359)
	Node = GetConVarBool(cvarNode);
	//Node = LibraryExists("repairnode");
	if (Node)
	{
		LogMessage("pingas");
		RegConsoleCmd("nodeon", Nodeon);
		RegConsoleCmd("nodeoff", Nodeoff);
	}
}
/*
public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "repairnode"))
    {
	if (!Node)
	{
	    Node = true;
	    RegConsoleCmd("nodeon", Nodeon);
	    RegConsoleCmd("nodeoff", Nodeoff);
	}
    }
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "repairnode"))
	Node = false;
}
*/

public Action:Nodeon(client, args)
{	
	if (!UseRepairNode[client])
		RemoveDisp(client);
	UseRepairNode[client]=true;
	return Plugin_Continue;
}

public Action:Nodeoff(client, args)
{	
	if (UseRepairNode[client])
	{
		RemoveDisp(client);
		AmpPanel(client);
	}
	UseRepairNode[client]=false;
	return Plugin_Continue;
}

RemoveDisp(client,offnode=false)
{
	new String:classname[64];
	new ent;
	if (offnode && Node)
	{
		UseRepairNode[client]=false;		
		FakeClientCommand(client, "nodeoff");		//Toggle Off Repair Node
	}
	for (new j=1;j<ME;j++)
	{
		ent=EntRefToEntIndex(BuildingRef[j]);
		if (ent>0)
		{
			GetEdictClassname(ent, classname, sizeof(classname));
			if (!strcmp(classname, "obj_dispenser") && (GetEntPropEnt(ent, Prop_Send, "m_hBuilder")==client))
			{
				Format(classname,64,"%i",GetEntPropEnt(ent, Prop_Send, "m_iMaxHealth")+1);
				SetVariantString(classname);
				AcceptEntityInput(ent, "RemoveHealth");
				FakeClientCommand(client, "destroy 0");
				
				new Handle:event = CreateEvent("object_removed", true);
				SetEventInt(event, "userid", GetClientUserId(client));
				SetEventInt(event, "index", ent);
				FireEvent(event);
				AcceptEntityInput(ent, "kill");
			}
		}
	}
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvarMetal)
        	MetalPerPlayer = StringToInt(newValue);
	else if (convar == cvarMetalMax)
        	MetalMax = StringToInt(newValue);
	else if (convar == cvarRegeneration)
        	MetalRegeneration = StringToInt(newValue);
	else if (convar == cvarDistance)
        	DefaultDistance = StringToFloat(newValue);
	else if (convar == cvarCondition)
        	DefaultCondition = TFCond:StringToInt(newValue);
	else if (convar == cvarMiniCritToSG)
        	MiniCritToSG = bool:StringToInt(newValue);
	else if (convar == cvarParticle)
        	ShowParticle = bool:StringToInt(newValue);
	else if (convar == cvarWallBlock)
        	WallBlock = bool:StringToInt(newValue);
	else if (convar == cvarPercent)
        	DefaultPercent = StringToInt(newValue);
	else if (convar == cvarNode)
	{
		Node = bool:StringToInt(newValue);
		if (Node)
		{
			RegConsoleCmd("nodeon", Nodeon);
			RegConsoleCmd("nodeoff", Nodeoff);
		}
	}
}

public OnConfigsExecuted()
{
	DefaultCondition = TFCond:GetConVarInt(cvarCondition);
	DefaultDistance = GetConVarFloat(cvarDistance);
	DefaultPercent = GetConVarInt(cvarPercent);
	MiniCritToSG = GetConVarBool(cvarMiniCritToSG);
	ShowParticle = GetConVarBool(cvarParticle);
	WallBlock = GetConVarBool(cvarWallBlock);
	Node = GetConVarBool(cvarNode);

	MetalRegeneration = GetConVarInt(cvarRegeneration);
	MetalPerPlayer = GetConVarInt(cvarMetal);
	MetalMax = GetConVarInt(cvarMetalMax);
}

public OnMapStart()
{
	AddToDownload();

	new String:strLine[256];
	Format(strLine,256,"%s.mdl",AmplifierModel);
	PrecacheModel(strLine, true);
	PrecacheModel(strLine, false);
	for (new i=1; i <=8; i++)
	{
		Format(strLine,256,"%s%i.mdl",AMPgib, i);
		PrecacheModel(strLine, true);
		PrecacheModel(strLine, false);
	}
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");

	new Float:time = GetConVarFloat(cvarAnnounce);
	if (time > 0.0 && !NativeControl)
		CreateTimer(time, Timer_Announce, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnClientAuthorized(client, const String:auth[])
{
	UseAmplifier[client]=false;
	UseRepairNode[client]=false;
	DontAsk[client]=false;
}

public Action:Timer_Announce(Handle:hTimer)
{
	if (NativeControl || GetConVarFloat(cvarAnnounce) <= 0.0)
		return Plugin_Stop;
	else
	{
		CPrintToChatAll("%t", "AmplifierM");
		CPrintToChatAll("%t", "AmplifierN");

		return Plugin_Continue;
	}
}

public AddToDownload()
{
	new String:strLine[256];
	new String:extensions[][] = {".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd", ".phy"};
	new String:extensionsb[][] = {".vtf", ".vmt"};
	for (new i=0; i < sizeof(extensions); i++)
	{
		Format(strLine,256,"%s%s",AmplifierModel,extensions[i]);
		AddFileToDownloadsTable(strLine);
		for (new j=1; j <=8; j++)
		{
			Format(strLine,256,"%s%i%s",AMPgib,j,extensions[i]);
			AddFileToDownloadsTable(strLine);
		}
	}
	for (new i=0; i < sizeof(extensionsb); i++)
	{
		Format(strLine,256,"%s%s",AmplifierTex,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"%s_blue%s",AmplifierTex,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"%s_anim%s",AmplifierTex,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"%s_anim_blue%s",AmplifierTex,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"%s_anim2%s",AmplifierTex,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"%s_anim2_blue%s",AmplifierTex,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"%s_holo%s",AmplifierTex,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"%s_bolt%s",AmplifierTex,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"%s_holo_blue%s",AmplifierTex,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"%s_radar%s",AmplifierTex,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
	}
	Format(strLine,256,"%s.mdl",AmplifierModel);
	PrecacheModel(strLine, true);
	PrecacheModel(strLine, false);
	for (new i=1; i <=8; i++)
	{
		Format(strLine,256,"%s%i.mdl",AMPgib,i);
		PrecacheModel(strLine, true);
		PrecacheModel(strLine, false);
	}
}

//Clean all Amplifiers' Data
/*
public Action:event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i=1;i<GetClientCount();i++)
	{
		AmplifierEnt[i]=0;
		for(new j=0;j<3;j++) 
			AmplifierPos[j][i]=0.0;
	}
	return Plugin_Continue;
}

public objectHealthChanged(const String:output[], caller, activator, Float:delay)
{
	for (new i=1;i<MP;i++)
	if ((EntRefToEntIndex(AmplifierEnt[i])==caller) && UseAmplifier[i])
	{
		new String:s[256];
		Format(s,256,"%s%s",AmplifierModel,".mdl"); 
		SetEntityModel(caller,s);
		break;
	}
	return Plugin_Continue;
}
*/

//Show Panel to Engineer on spawn.
public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!NativeControl)
	{
		new client=GetClientOfUserId(GetEventInt(event, "userid"));
		if (!DontAsk[client])
			AmpPanel(client);		
	}
	return Plugin_Continue;
}

public AmpHelpPanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
		return;   
}
  
public Action:HelpPanel(client, Args)
{
	new Handle:panel = CreatePanel();
	new String:s[256];
	SetGlobalTransTarget(client);
	Format(s,256,"%t","Amplifier1");
	SetPanelTitle(panel, s);
	Format(s,256,"%t","Amplifier2");
	DrawPanelText(panel, s);
	Format(s,256,"%t","Amplifier3");
	DrawPanelText(panel, s);
	Format(s,256,"%t","Amplifier4");
	DrawPanelText(panel, s);
	Format(s,256,"%t","Amplifier5");
	DrawPanelText(panel, s);
	DrawPanelItem(panel, "Close Menu");  
	SendPanelToClient(panel, client, AmpHelpPanelH, 16);
	CloseHandle(panel);
}

//Show Panel to Enginner on command
public Action:CallPanel(client, Args)
{
	if (!NativeControl)
		AmpPanel(client);

	return Plugin_Continue;
}

//Panel's procedure
public AmpPanel(client)
{		
	if (NativeControl || TF2_GetPlayerClass(client) != TFClass_Engineer)
		return;// Plugin_Continue;
		
	new Handle:panel = CreatePanel();
	new String:str[256];
	SetGlobalTransTarget(client);
	Format(str,256,"%t","AmplifierA");
	//str="Selct your 2nd building";
	SetPanelTitle(panel, str);
	
	Format(str,256,"%t","AmplifierB");
	//str="Dispenser";
	DrawPanelItem(panel, str);
	
	Format(str,256,"%t","AmplifierC");
	//str="Amplifier";
	DrawPanelItem(panel, str); 
	
	Format(str,256,"%t","AmplifierD");
	//str="Dispenser, don't ask me again";
	DrawPanelItem(panel, str); 
	
	Format(str,256,"%t","AmplifierE");
	//str="Amplifier, don't ask me again";
	DrawPanelItem(panel, str); 
	
	SendPanelToClient(panel, client, AmpPanelH, 20);
	CloseHandle(panel); 
	//return Plugin_Continue;	
}

//Panel's Handle Procedure
public AmpPanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1:
			{
				if (UseAmplifier[param1])
					RemoveDisp(param1,true);
				UseAmplifier[param1]=false;
				DontAsk[param1]=false;
			}
			case 2:
			{
				if (!UseAmplifier[param1])
					RemoveDisp(param1,true);
				UseAmplifier[param1]=true;
				DontAsk[param1]=false;
			}
			case 3:
			{
				if (UseAmplifier[param1])
					RemoveDisp(param1,true);
				UseAmplifier[param1]=false;
				DontAsk[param1]=true;
				CPrintToChat(param1,"%t", "AmplifierM");
			}
			case 4:
			{
				if (!UseAmplifier[param1])
					RemoveDisp(param1,true);
				UseAmplifier[param1]=true;
				DontAsk[param1]=true;
				CPrintToChat(param1,"%t", "AmplifierM");
			}
		}
		if (Node && UseRepairNode[param1])
			FakeClientCommand(param1, "nodeoff");		//Toggle Off Repair Node
		//FakeClientCommand(param1, "LucyCharm");		//Coming Soon: Lucy Charm
	}
}

//Main timer:
//--Detect players near (or not) Amplifiers.
//--Spawn (Remove) crit effects on players. 
//--Disable Amplifiers when they dying
//--WAVES
public Action:Timer_amplifier(Handle:hTimer)
{
	new Float:Pos[3];
	new Float:AmplifierPos[3];
	new TFTeam:clientTeam;
	new TFTeam:team;
	new i,client;
	new maxEntities = GetMaxEntities();
	new String:modelname[256];
	for(client=1;client<=MaxClients;client++)
	{
		if (IsClientInGame(client)) 
		{
			NearAmplifier[client]=false;
			if (IsPlayerAlive(client) && IsValidEdict(client)) 
			{
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", Pos);  //Get player's position
				clientTeam=TFTeam:GetClientTeam(client);

				for(i=1;i<maxEntities;i++) //See all Amplifiers
				{
					new amp = EntRefToEntIndex(BuildingRef[i]);
					if (amp>0)
						GetEntPropString(i, Prop_Data, "m_ModelName", modelname, 128);
					if ((amp>0) && (StrContains(modelname,"plifier")>-1))	//Force off AMP's effect on Dispenser and Rep.Node
					{
						//If Amplifier Exist, Active and not sapped
						if (AmplifierOn[amp] && !AmplifierSapped[amp])
						{
							// Check Metal
							new metal = GetEntProp(amp, Prop_Send, "m_iAmmoMetal");
							if (metal < MetalPerPlayer && MetalPerPlayer > 0)
								continue;
	
							// Check Percent Chance
							new percent = AmplifierPercent[amp];
							if (percent < 100 && (ConditionApplied[amp][client] || GetRandomInt(1,100) > percent))
								continue;

							new bool:enableParticle;
							new TFCond:Condition = AmplifierCondition[amp];
							switch (Condition)
							{
								case TFCond_Ubercharged, TFCond_Kritzkrieged, TFCond_Buffed,
									TFCond_DemoBuff, TFCond_Charging, TFCond_MegaHeal, TFCond_RegenBuffed,
									TFCond_SpeedBuffAlly, TFCond_CritHype, TFCond_CritOnFirstBlood, TFCond_CritOnWin,
									TFCond_CritOnKill, TFCond_HalloweenCritCandy, TFCond_DefenseBuffed:
								{
									enableParticle = (Condition != TFCond_Buffed && Condition != TFCond_DefenseBuffed && Condition != TFCond_MegaHeal) && ShowParticle;
									team = TFTeam:GetEntProp(amp, Prop_Send, "m_iTeamNum");
								}
								case TFCond_Slowed, TFCond_Zoomed, TFCond_TeleportedGlow, TFCond_Taunting,
									TFCond_Bonked, TFCond_Dazed, TFCond_OnFire, TFCond_Jarated, TFCond_Milked, TFCond_MarkedForDeath, TFCond_RestrictToMelee,
									TFCond_Disguised, TFCond_Cloaked, TFCond_CloakFlicker:
								{
									enableParticle = false;
									team = (TFTeam:GetEntProp(amp, Prop_Send, "m_iTeamNum") == TFTeam_Red)
										? TFTeam_Blue : TFTeam_Red;
								}
								default:
								{
									enableParticle = false;
									team = TFTeam:GetEntProp(amp, Prop_Send, "m_iTeamNum");
								}
							}
							//Spy can use enemies' Amplifier
							//new pcond = TF2_GetPlayerConditionFlags(client);
							if ((TF2_GetPlayerClass(client) == TFClass_Spy) && TF2_IsPlayerInCondition(client, TFCond_Disguised) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
							{
								team=clientTeam;
							}
						
							GetEntPropVector(amp, Prop_Send, "m_vecOrigin", AmplifierPos);

							if (clientTeam==team &&
								GetVectorDistance(Pos,AmplifierPos) <= AmplifierDistance[amp] &&
								(!WallBlock || TraceTargetIndex(amp, client, AmplifierPos, Pos)))
							{
								new Action:res = Plugin_Continue;
								new builder = GetEntPropEnt(amp, Prop_Send, "m_hBuilder");
	
								Call_StartForward(fwdOnAmplify);
								Call_PushCell(builder);
								Call_PushCell(client);
								Call_PushCell(Condition);
								Call_Finish(res);
	
								if (res != Plugin_Continue)
									continue;

								//If player in Amplifier's distance and on Amplifier's team
								if (enableParticle)
								{
									//If Crit Effect does NOT Exist
									new particle = EntRefToEntIndex(GetPar[client]);
									if (particle==0 || !IsValidEntity(particle))
									{
										//Create Buffed Effect
										if (team==TFTeam_Red)
											AttachParticle(client,"soldierbuff_red_buffed",particle);
										else
											AttachParticle(client,"soldierbuff_blue_buffed",particle);
										GetPar[client] = EntIndexToEntRef(particle);
									}
								}
								new String:weapon[64];
								GetClientWeapon(client, weapon, 64); 

								//Set condition to player
								if (Condition == TFCond_OnFire)
								{
									if (builder > 0)
										TF2_IgnitePlayer(client, builder);
								}
								else if (Condition == TFCond_Zoomed)
								{
									if (TF2_GetPlayerClass(client) == TFClass_Sniper)
										TF2_AddCondition(client, Condition, 1.0);
								}
								else if (Condition == TFCond_Taunting)
									FakeClientCommand(client, "taunt");
								else if (Condition == TFCond_Disguised || Condition == TFCond_Cloaked)
									TF2_RemoveCondition(client, Condition);
								else if (Condition == TFCond_RestrictToMelee)
								{
									TF2_AddCondition(client, Condition, 1.0);
									if (!strcmp(weapon, "tf_weapon_minigun", false))
									{
										SetEntProp(GetPlayerWeaponSlot(client, TFWeaponSlot_Primary), Prop_Send, "m_iWeaponState", 0);
										TF2_RemoveCondition(client, TFCond_Slowed);
									}
									new melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
									if (melee > MaxClients && IsValidEntity(melee)) SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", melee);
								}
								else if ((Condition == TFCond_Kritzkrieged) && (TF2_GetPlayerClass(client) == TFClass_Engineer) && StrEqual(weapon, "tf_weapon_sentry_revenge"))
								{
									if (Revenges[client]==0)
										Revenges[client]=GetEntProp(client, Prop_Send, "m_iRevengeCrits")+2;
									SetEntProp(client, Prop_Send, "m_iRevengeCrits", Revenges[client]);	//Eggineer with Frontier Justice
								}
								else if (TF2_IsCritCondition(Condition) && MiniCritToSG && (TF2_GetPlayerClass(client) == TFClass_Engineer) && StrEqual(weapon, "tf_weapon_laser_pointer"))
									TF2_AddCondition(client, TFCond_Buffed, 2.0);							
								else
									TF2_AddCondition(client, Condition, 1.0);
								
								ConditionApplied[amp][client]=true;
								NearAmplifier[client]=true;

								if (MetalPerPlayer > 0)
								{
									metal -= MetalPerPlayer;
									SetEntProp(amp, Prop_Send, "m_iAmmoMetal", metal);
								}
								break;
							} 
						}

						// Only remove conditions that were set by the amplifier
						if (amp > 0 && !NearAmplifier[client] && ConditionApplied[amp][client])
						{
							ConditionApplied[amp][client]=false;
							new String:weapon[64];
							GetClientWeapon(client, weapon, 64); 
							if (MiniCritToSG && (TF2_GetPlayerClass(client) == TFClass_Engineer) && StrEqual(weapon, "tf_weapon_laser_pointer") && (AmplifierCondition[amp]!=TFCond_Buffed))
							TF2_RemoveCondition(client, TFCond_Buffed);							
							TF2_RemoveCondition(client, AmplifierCondition[amp]);
							if (Revenges[client]>2)							
								SetEntProp(client, Prop_Send, "m_iRevengeCrits", Revenges[client]-2);
							else
								SetEntProp(client, Prop_Send, "m_iRevengeCrits", 0);
							Revenges[client]=0;
						}
					}
				}
			}

			//if Amplifiers on distance not found or client is dead
			if ((i==maxEntities) || !IsPlayerAlive(client))
			{
				//if player has crit effect - delete it
				new particle = EntRefToEntIndex(GetPar[client]);
				if (particle != 0 && IsValidEntity(particle))
				{
					RemoveEdict(particle);
				}
				GetPar[client]=0;
			}
		}
	}

	//Amplifier's waves
	for(i=1;i<maxEntities;i++)
	{
		new ref = BuildingRef[i];
		if (ref != 0)
		{
			new ent = EntRefToEntIndex(ref);
			if (ent > 0)
			{
				GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, 128);	
				if (AmplifierOn[ent] && !AmplifierSapped[ent] && (StrContains(modelname,"plifier")>-1))
				{
					//Brootforse heal bug fix
					if (GetEntProp(ent, Prop_Send, "m_bDisabled")==0)
						SetEntProp(ent, Prop_Send, "m_bDisabled", 1);
							
					new metal=GetEntProp(ent, Prop_Send, "m_iUpgradeMetal")*(MetalMax/200);
					
					if (metal>0)
					{
						if (GetEntProp(ent, Prop_Send, "m_iAmmoMetal")<MetalMax-metal)
							SetEntProp(ent, Prop_Send, "m_iAmmoMetal",GetEntProp(ent, Prop_Send, "m_iAmmoMetal")+metal);
						else
							SetEntProp(ent, Prop_Send, "m_iAmmoMetal",MetalMax);
						SetEntProp(ent, Prop_Send, "m_iUpgradeMetal",0);
					}
					
					if (MetalRegeneration > 0 || MetalPerPlayer > 0)
					{
						metal = GetEntProp(ent, Prop_Send, "m_iAmmoMetal") + MetalRegeneration;
						if (metal <= MetalMax)
							SetEntProp(ent, Prop_Send, "m_iAmmoMetal", metal);

						if (metal < MetalPerPlayer)
							continue;
					}
					else
						metal = 255;

					new beamColor[4];
					switch (AmplifierCondition[ent])
					{
					    case TFCond_Slowed, TFCond_Zoomed, TFCond_Disguised, TFCond_Cloaked, TFCond_CloakFlicker, TFCond_TeleportedGlow, TFCond_Taunting,
						 TFCond_Bonked, TFCond_Dazed, TFCond_OnFire, TFCond_Jarated, TFCond_Milked, TFCond_MarkedForDeath, TFCond_RestrictToMelee:
					    {
							beamColor = {255, 255, 75, 255}; // Yellow
					    }
					    //case TFCond_Ubercharged, TFCond_Kritzkrieged, TFCond_Buffed,
					    //     TFCond_DemoBuff, TFCond_Charging:
					    default:
					    {
							if (TFTeam:GetEntProp(ent, Prop_Send, "m_iTeamNum")==TFTeam_Red)
								beamColor = {255, 75, 75, 255}; // Red
							else
								beamColor = {75, 75, 255, 255}; // Blue
					    }
					}

					if (metal < 255)
					    beamColor[3] = metal;

					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", Pos);
					Pos[2]+=90;
					TE_SetupBeamRingPoint(Pos, 10.0, AmplifierDistance[ent]+100.1, g_BeamSprite, g_HaloSprite, 0, 15, 3.0, 5.0, 0.0, beamColor, 3, 0);
					TE_SendToAll();		
				}
			}
			else
			{
				// The amplifier is no longer valid (was destroyed)
				BuildingRef[i] = 0;

				// Remove any lingering conditions
				for(client=1;client<=MaxClients;client++)
				{
					if (ConditionApplied[i][client])
					{
						ConditionApplied[i][client]=false;
						if (IsClientInGame(client) && IsPlayerAlive(client)) 
							TF2_RemoveCondition(client, AmplifierCondition[i]);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}
stock TF2_IsCritCondition(TFCond:cond)
{
	switch (cond)
	{
		case TFCond_Kritzkrieged, TFCond_HalloweenCritCandy, (TFCond:34), (TFCond:35), TFCond_CritOnFirstBlood, TFCond_CritOnWin, TFCond_CritOnFlagCapture, TFCond_CritOnKill: return true;
		default: return false;
	}
	return false;
}
//Add scores for engi for assist by Amplifier
public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	//new Float:Pos[3];
	//new Float:AmplifierPos[3];
	new Victim = GetClientOfUserId(GetEventInt(event,"userid"));
	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (NearAmplifier[Attacker] || NearAmplifier[Victim])
	{
		new maxEntities = GetMaxEntities();
		for(new i=1;i<maxEntities;i++)
		{
			new ent = EntRefToEntIndex(BuildingRef[i]);
			if (ent > 0 && AmplifierOn[ent] && !AmplifierSapped[ent] && (Attacker!=i))
			{
				//GetEntPropVector(Attacker, Prop_Send, "m_vecOrigin", Pos);
				//GetEntPropVector(ent, Prop_Send, "m_vecOrigin", AmplifierPos);
				//if (GetVectorDistance(Pos,AmplifierPos)<=AmplifierDistance[ent])
				new bool:assist;
				switch (AmplifierCondition[ent])
				{
					case TFCond_Slowed, TFCond_Zoomed, TFCond_TeleportedGlow, TFCond_Taunting,
					     TFCond_Bonked, TFCond_Dazed, TFCond_OnFire, TFCond_Jarated, TFCond_Milked, TFCond_MarkedForDeath, TFCond_RestrictToMelee:
					{
						assist = ConditionApplied[ent][Victim];
					}
					default:
						assist = ConditionApplied[ent][Attacker];
				}

				if (assist)
				{
					new builder = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
					if (builder > 0)
					{
						EngiAssists[builder]++;
						if (EngiAssists[builder]>=4)
						{
							new Handle:aevent = CreateEvent("player_escort_score", true) ;
							SetEventInt(aevent, "player", builder);
							SetEventInt(aevent, "points", 1);
							FireEvent(aevent);
							EngiAssists[builder]=0;
						}
					}
					break;
				}
			}
		}
	}
	return Plugin_Continue;
}


//Detect building
public Action:Event_Build(Handle:event, const String:name[], bool:dontBroadcast)
{
	new ent = GetEventInt(event, "index");
	CheckDisp(ent);
	CheckSapper(ent);
	return Plugin_Continue;
}

//if building is dispenser
CheckDisp(ent)
{
	new String:classname[64];
	new Client=GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
	GetEdictClassname(ent, classname, sizeof(classname));
	if (!strcmp(classname, "obj_dispenser"))
	{	  
		BuildingRef[ent]=EntIndexToEntRef(ent);
		if (UseRepairNode[Client])
		{
			UseAmplifier[Client]=false;
			SetEntProp(ent, Prop_Send, "m_bDisabled", 1);
		}
		if ((Client <= 0) || !UseAmplifier[Client]) //Don't create Amplifier if player don't want it...or has Repair Node
			return;// Plugin_Continue;
		
		new Float:pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);  
		AmplifierOn[ent]=false;
		SetEntProp(ent, Prop_Send, "m_bDisabled", 1);
		AmplifierSapped[ent]=false;
		AmplifierPercent[ent]=NativeControl ? NativePercent[Client] : DefaultPercent;
		AmplifierDistance[ent]=NativeControl ? NativeDistance[Client] : DefaultDistance;
		AmplifierCondition[ent]=NativeControl ? NativeCondition[Client] : DefaultCondition;
		new String:s[128];
		Format(s,128,"%s%s",AmplifierModel,".mdl");
		SetEntityModel(ent,s);
		SetEntProp(ent, Prop_Send, "m_nSkin", GetEntProp(ent, Prop_Send, "m_nSkin")+2);
		CreateTimer(4.0, DispCheckStage1, EntIndexToEntRef(ent));
	}
	return;// Plugin_Continue;
}


//Wait 3 seconds before check model to change
public Action:DispCheckStage1(Handle:hTimer,any:ref)
{
	if (EntRefToEntIndex(ref) > 0)
		CreateTimer(0.1, DispCheckStage2, ref, TIMER_REPEAT);
	return Plugin_Continue;
}

//Change model if it's not Amplifier's model
public Action:DispCheckStage2(Handle:hTimer,any:ref)
{
	new ent = EntRefToEntIndex(ref);
	if (ent > 0 && IsValidEntity(ent))
	{
		new String:modelname[128];

		/*
		GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, 128);
		if (StrContains(modelname,"dispenser")==-1)
			return Plugin_Continue;
		*/

		if (GetEntPropFloat(ent, Prop_Send, "m_flPercentageConstructed") < 1.0)
			return Plugin_Continue;

		AmplifierOn[ent]=true;
		Format(modelname,128,"%s%s",AmplifierModel,".mdl");
		SetEntProp(ent, Prop_Send, "m_iUpgradeLevel",1);
		SetEntityModel(ent,modelname);
		SetEntProp(ent, Prop_Send, "m_iMaxHealth",216);
		SetVariantString("-66");
		AcceptEntityInput(ent, "RemoveHealth");
		SetEntProp(ent, Prop_Send, "m_nSkin", GetEntProp(ent, Prop_Send, "m_nSkin")-2);

		new particle;
		if (TFTeam:GetEntProp(ent, Prop_Send, "m_iTeamNum")==TFTeam_Red)
			AttachParticle(ent,"teleported_red",particle); //Create Effect of TP
		else
			AttachParticle(ent,"teleported_blue",particle); //Create Effect of TP
		CreateTimer(2.0, DispCheckStage1a, EntIndexToEntRef(particle));
	}
	KillTimer(hTimer);
	return Plugin_Continue;
}

//Wait for kill teleport effect
public Action:DispCheckStage1a(Handle:hTimer,any:ref)
{
	new ent = EntRefToEntIndex(ref);
	if (ent > 0 && IsValidEntity(ent))
		RemoveEdict(ent);

	return Plugin_Continue;
}
//Spa suppin' mah Amplifier!!!!11
CheckSapper(ent)
{
	CreateTimer(0.5, SapperCheckStage1,EntIndexToEntRef(ent));	
	//return Plugin_Continue;
}

public Action:SapperCheckStage1(Handle:hTimer,any:ref)
{
	new ent = EntRefToEntIndex(ref);
	if (ent > 0 && IsValidEntity(ent))
	{
		new String:classname[64];
		GetEdictClassname(ent, classname, sizeof(classname));
		if (!strcmp(classname, "obj_attachment_sapper"))
		{
			new maxEntities = GetMaxEntities();
			for (new i=1;i<maxEntities;i++)
			{
				new ampref = BuildingRef[i];
				new ampent = EntRefToEntIndex(ampref);
				if (ampent > 0)
				{
					if ((GetEntProp(ampent, Prop_Send, "m_bHasSapper")==1) && !AmplifierSapped[ampent])
					{
						AmplifierSapped[ampent]=true;
						CreateTimer(0.2, SapperCheckStage2,ampref,TIMER_REPEAT);
						break;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:SapperCheckStage2(Handle:hTimer,any:ref)
{
	new ent = EntRefToEntIndex(ref);
	if (ent > 0 && IsValidEntity(ent))
	{
		if ((GetEntProp(ent, Prop_Send, "m_bHasSapper")==0) && AmplifierSapped[ent])
		{
			AmplifierSapped[ent]=false;
			KillTimer(hTimer);
		}		
	}		
	return Plugin_Continue;
}

/* With COND extension i can kill this bugged function
//Generate 100% crit if player near Amplifier 
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (!NearAmplifier[client])
		return Plugin_Continue;
	else
	{
		result = true;	
		return Plugin_Handled;
	}
}
*/

//Create Crit Particle
AttachParticle(ent, String:particleType[],&particle)
{
	particle = CreateEntityByName("info_particle_system");
	
	new String:tName[128];
	new Float:pos[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
	TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
	
	Format(tName, sizeof(tName), "target%i", ent);
	DispatchKeyValue(ent, "targetname", tName);
	
	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", tName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(tName);
	AcceptEntityInput(particle, "SetParent", particle, particle, 0);
	//SetVariantString("none");
	//AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
}

stock CleanString(String:strBuffer[])
{
	// Cleanup any illegal characters
	new Length = strlen(strBuffer);
	for (new i=0; i<Length; i++)
	{
		switch(strBuffer[i])
		{
			case '\r': strBuffer[i] = ' ';
			case '\n': strBuffer[i] = ' ';
			case '\t': strBuffer[i] = ' ';
		}
	}

	// Trim string
	TrimString(strBuffer);
}

/**
 * Description: Native Interface
 */

public Native_ControlAmplifier(Handle:plugin,numParams)
{
	NativeControl = GetNativeCell(1);
}

public Native_SetAmplifier(Handle:plugin,numParams)
{
	new client = GetNativeCell(1);
	UseAmplifier[client] = bool:GetNativeCell(2);

	new Float:distance = Float:GetNativeCell(3);
	NativeDistance[client] = (distance < 0.0) ? DefaultDistance : distance;

	new TFCond:condition = TFCond:GetNativeCell(4);
	NativeCondition[client] = (condition < TFCond_Slowed) ? DefaultCondition : condition;

	new percent = GetNativeCell(5);
	NativePercent[client] = (distance < 0) ? DefaultPercent : percent;
}

public Native_HasAmplifier(Handle:plugin,numParams)
{
	new count = 0;
	new client = GetNativeCell(1);
	new maxEntities = GetMaxEntities();
	for (new i=1;i<maxEntities;i++)
	{
		new ampref = BuildingRef[i];
		new ampent = EntRefToEntIndex(ampref);
		if (ampent > 0)
		{
			if (GetEntPropEnt(ampent, Prop_Send, "m_hBuilder") == client)
				count++;
		}
	}
	return count;
}

public Native_ConvertToAmplifier(Handle:plugin,numParams)
{
	new ent = GetNativeCell(1);
	if (ent > 0 && IsValidEntity(ent))
	{
		new client = GetNativeCell(2);
		new bool:save = UseAmplifier[client];
		new Float:saveDist = NativeDistance[client];
		new TFCond:saveCond = NativeCondition[client];
		new savePercent = NativePercent[client];

		new Float:distance = Float:GetNativeCell(3);
		if (distance >= 0.0)
			NativeDistance[client] = distance;

		new TFCond:condition = TFCond:GetNativeCell(4);
		if (condition >= TFCond_Slowed)
			NativeCondition[client] = condition;

		new percent = GetNativeCell(5);
		if (percent >= 0)
			NativePercent[client] =  percent;

		UseAmplifier[client] = true;
		CheckDisp(ent);

		NativeCondition[client] = saveCond;
		NativeDistance[client] = saveDist;
		NativePercent[client] = savePercent;
		UseAmplifier[client] = save;
	}
}

#if defined _ztf2grab_included
public Action:OnPickupObject(client, builder, ent)
{
	if (BuildingRef[ent] != 0 && EntRefToEntIndex(BuildingRef[ent]) == ent)
	{
		switch (AmplifierCondition[ent])
		{
			case TFCond_Ubercharged, TFCond_Kritzkrieged, TFCond_Buffed:
				return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}
#endif

/**
 * Description: Ray Trace functions and variables
 */
#tryinclude <raytrace>
#if !defined _raytrace_included
stock bool:TraceTargetIndex(client, target, Float:clientLoc[3], Float:targetLoc[3])
{
	targetLoc[2] += 50.0; // Adjust trace position of target
	TR_TraceRayFilter(clientLoc, targetLoc, MASK_SOLID,
					  RayType_EndPoint, TraceRayDontHitSelf,
					  client);

	return (!TR_DidHit() || TR_GetEntityIndex() == target);
}

/***************
 *Trace Filters*
****************/

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	return (entity != data); // Check if the TraceRay hit the owning entity.
}
#endif
