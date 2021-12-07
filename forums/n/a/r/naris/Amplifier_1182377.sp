 #pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <colors>

#define MP 33
#define distance 200

new g_BeamSprite;
new g_HaloSprite;
new redColor[4]		= {255, 75, 75, 255};
new blueColor[4]	= {75, 75, 255, 255};

new bool:UseAmplifier[MP]=false;
new bool:DontAsk[MP]=false;
new bool:NearAmplifier[MP]=false;
new bool:AmplifierOn[MP]=false;
new bool:AmplifierSapped[MP]=false;
new GetPar[MP];
new TPPar[MP];
new Float:AmplifierPos[3][MP];
new AmplifierTeam[MP];
new AmplifierEnt[MP];
new EngiAssists[MP]=0;

#define AmplifierModel "models/buildables/amplifier_test/amplifier"
#define AMPgib "models/buildables/amplifier_test/gibs/amp_gib"

public Plugin:myinfo = {
	name = "The Amplifier",
	author = "Eggman",
	description = "Add The Amplifier (crit dispenser)",
	version = "alpha",
};

public OnPluginStart()
{
	HookEvent("player_builtobject", Event_Build);
	CreateTimer(1.0, Timer_amplifier, _, TIMER_REPEAT);
	HookEvent("teamplay_round_start", event_RoundStart);
	HookEvent("player_spawn", Event_player_spawn);
	//HookEntityOutput("obj_dispenser", "OnObjectHealthChanged", objectHealthChanged);
	RegConsoleCmd("amplifier",        CallPanel, "Select 2nd engineer's building ");
	RegConsoleCmd("amp",        CallPanel, "Select 2nd engineer's building ");
	RegConsoleCmd("amp_help",        HelpPanel, "Show info Amplifier");
	AddToDownload();
	CreateTimer(250.0, Timer_Announce, _, TIMER_REPEAT);
	LoadTranslations("Amplifier");
	HookEvent("player_death", event_player_death);
}

public OnMapStart()
{
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
	AddToDownload();
}
public OnClientAuthorized(client, const String:auth[])
{
	UseAmplifier[client]=false;
	DontAsk[client]=false;
}

public Action:Timer_Announce(Handle:hTimer)
{
	CPrintToChatAll("%t", "AmplifierM");
	CPrintToChatAll("%t", "AmplifierN");

	return Plugin_Continue;
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
		Format(strLine,256,"materials/%s%s",AmplifierModel,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"materials/%s_blue%s",AmplifierModel,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"materials/%s_anim%s",AmplifierModel,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"materials/%s_anim_blue%s",AmplifierModel,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"materials/%s_anim2%s",AmplifierModel,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"materials/%s_anim2_blue%s",AmplifierModel,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"materials/%s_holo%s",AmplifierModel,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"materials/%s_bolt%s",AmplifierModel,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"materials/%s_holo_blue%s",AmplifierModel,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"materials/%s_radar%s",AmplifierModel,extensionsb[i]);
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

/*
public objectHealthChanged(const String:output[], caller, activator, Float:delay)
{
	for (new i=1;i<MP;i++)
	if ((AmplifierEnt[i]==caller) && UseAmplifier[i])
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
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	if (!DontAsk[client])
		AmpPanel(client);		
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
	AmpPanel(client);		
	return Plugin_Continue;
}

//Panel's procedure
public AmpPanel(client)
{		
	if (TF2_GetPlayerClass(client) != TFClass_Engineer)
		return;// Plugin_Continue;
		
	new Handle:panel = CreatePanel();
	new String:str[256];
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
				UseAmplifier[param1]=false;
				DontAsk[param1]=false;
			}
			case 2:
			{
				UseAmplifier[param1]=true;
				DontAsk[param1]=false;
			}
			case 3:
			{
				UseAmplifier[param1]=false;
				DontAsk[param1]=true;
				CPrintToChat(param1,"%t", "AmplifierM");
			}
			case 4:
			{
				UseAmplifier[param1]=true;
				DontAsk[param1]=true;
				CPrintToChat(param1,"%t", "AmplifierM");
			}
		}
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
	new String:str[256];
	new i,team,client;
	for(client=1;client<=GetClientCount();client++)
	{
		if (IsClientInGame(client)) 
		{
			if (IsPlayerAlive(client) && IsValidEdict(client)) 
			{
				NearAmplifier[client]=false;			//Set default crit chance to player
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", Pos);  //Get player's position
				//Next lines - detect team (spy detected as enemie's team)
				//--
				if (TFTeam:GetClientTeam(client)==TFTeam_Red)
					team=0;
				else
					team=1;
				//---
				for(i=1;i<MP;i++) //See all Amplifiers
				{
					if (!IsValidEdict(AmplifierEnt[i]))
						AmplifierEnt[i]=0;		
					else
					{
						GetEdictClassname(AmplifierEnt[i], str, sizeof(str));
						if (!StrEqual(str, "obj_dispenser", false))
							AmplifierEnt[i]=0;		
					}
					if ((AmplifierEnt[i]!=0) && AmplifierOn[i] && !AmplifierSapped[i])//If Amplifier Exist, Active and not supped
					{					
						if ((TF2_GetPlayerClass(client) == TFClass_Spy) && TF2_IsPlayerDisguised(client) && !(GetEntProp(client, Prop_Send, "m_nPlayerCond") & 16))	
							team=AmplifierTeam[i];	//Spy can use enemies' Amplifier
							
						if (GetEntProp(AmplifierEnt[i], Prop_Send, "m_bDisabled")==0)	//Brootforse heal bug fix
							SetEntProp(AmplifierEnt[i], Prop_Send, "m_bDisabled", 1);
						
						if ((calcDistance(Pos[0],AmplifierPos[0][i],Pos[1],AmplifierPos[1][i],Pos[2],AmplifierPos[2][i])<=distance) && (AmplifierTeam[i]==team))
							//If player in Amplifier's distance and on Amplifier's team
						{
							if (!IsValidEntity(GetPar[client]) || (GetPar[client]==0)) //If Crit Effect NOT Exists
							{
								if (team==0)
									AttachParticle(client,"soldierbuff_red_buffed",GetPar[client]); //Create RED Effect
								else
									AttachParticle(client,"soldierbuff_blue_buffed",GetPar[client]); //Create BLU Effect
							}
							NearAmplifier[client]=true;		//Set 100% crit to player
							break;
						} 
					}	
				}
			}
			
			if (NearAmplifier[client])
				TF2_AddCondition(client, TFCond_Kritzkrieged, 1.0);
			else
				TF2_RemoveCondition(client, TFCond_Kritzkrieged);
			
			if ((i==MP) || (!IsPlayerAlive(client)))	//if Amplifiers on distance not found or client is dead
			{
				if (IsValidEntity(GetPar[client]))		//if player has crit effect - delete it
				{
					GetEdictClassname(GetPar[client], str, sizeof(str));
					if (StrEqual(str, "info_particle_system", false))
						RemoveEdict(GetPar[client]);
				}
				GetPar[client]=0;
			}
			if (!IsValidEdict(AmplifierEnt[client]))
				AmplifierEnt[client]=0;			
			//Amplifier's waves
			if ((AmplifierEnt[client]!=0) && AmplifierOn[client] && !AmplifierSapped[client])
			{
				GetEdictClassname(AmplifierEnt[client], str, sizeof(str));
				if (StrEqual(str, "obj_dispenser", false))
				{
					GetEntPropVector(AmplifierEnt[client], Prop_Send, "m_vecOrigin", Pos);
					Pos[2]+=90;
					if (AmplifierTeam[client]==0)
						TE_SetupBeamRingPoint(Pos, 10.0, 300.1, g_BeamSprite, g_HaloSprite, 0, 15, 3.0, 5.0, 0.0, redColor, 3, 0);
					else
						TE_SetupBeamRingPoint(Pos, 10.0, 300.1, g_BeamSprite, g_HaloSprite, 0, 15, 3.0, 5.0, 0.0, blueColor, 3, 0);
					TE_SendToAll();		
				}
			}
		}
	}
	return Plugin_Continue;
}

//Add scores for engi for assist by Amplifier
public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Float:Pos[3];
	if (NearAmplifier[Attacker])
	{
		for(new i=1;i<MP;i++)
		{
			if ((AmplifierEnt[i]!=0) && AmplifierOn[i] && !AmplifierSapped[i] && (Attacker!=i))
			{
				GetEntPropVector(Attacker, Prop_Send, "m_vecOrigin", Pos);
				if (calcDistance(Pos[0],AmplifierPos[0][i],Pos[1],AmplifierPos[1][i],Pos[2],AmplifierPos[2][i])<=distance)
				{			
					EngiAssists[i]++;
					if (EngiAssists[i]>=4)
					{
						new Handle:aevent = CreateEvent("player_escort_score", true) ;
						SetEventInt(aevent, "player", i);
						SetEventInt(aevent, "points", 1);
						FireEvent(aevent);
						EngiAssists[i]=0;
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
	CheckDisp(GetEventInt(event, "object"), GetEventInt(event, "index"), GetEventInt(event, "userid"));
	CheckSapper(GetEventInt(event, "object"), GetEventInt(event, "index"), GetEventInt(event, "userid"));
	return Plugin_Continue;
}
//if building is dispenser
public CheckDisp(object, ent, userid)
{
	object=GetClientOfUserId(userid);
	if (!UseAmplifier[object]) //Don't create Amplifier if player don't want it
		return;// Plugin_Continue;
	new String:classname[64];
	GetEdictClassname(ent, classname, sizeof(classname));
	if (!strcmp(classname, "obj_dispenser"))
	{
		new Float:pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);    
		SetEntProp(ent, Prop_Send, "m_bDisabled", 1);
		if (TFTeam:GetClientTeam(object)==TFTeam_Red)
			AmplifierTeam[object]=0;
		else
			AmplifierTeam[object]=1;
		AmplifierPos[0][object]=pos[0];
		AmplifierPos[1][object]=pos[1];
		AmplifierPos[2][object]=pos[2];
		AmplifierEnt[object]=ent;
		AmplifierOn[object]=false;
		AmplifierSapped[object]=false;
		new String:s[128];
		Format(s,128,"%s%s",AmplifierModel,".mdl");
		SetEntityModel(ent,s);
		SetEntProp(ent, Prop_Send, "m_nSkin", GetEntProp(ent, Prop_Send, "m_nSkin")+2);
		CreateTimer(4.0, DispCheckStage1, object);
	}
	return;// Plugin_Continue;
}


//Wait 3 seconds before check model to change
public Action:DispCheckStage1(Handle:hTimer,any:Client)
{
	CreateTimer(0.1, DispCheckStage2, Client, TIMER_REPEAT);
	return Plugin_Continue;
}

//Change model if it's not Amplifier's model
public Action:DispCheckStage2(Handle:hTimer,any:Client)
{
	if (!IsValidEntity(AmplifierEnt[Client]))
	{
		KillTimer(hTimer);
		return Plugin_Continue;
	}
	new String:modelname[128];
	GetEntPropString(AmplifierEnt[Client], Prop_Data, "m_ModelName", modelname, 128);
	if (StrContains(modelname,"dispenser")==-1)
		return Plugin_Continue;
	AmplifierOn[Client]=true;
	Format(modelname,128,"%s%s",AmplifierModel,".mdl");
	SetEntityModel(AmplifierEnt[Client],modelname);
	KillTimer(hTimer);
	SetEntProp(AmplifierEnt[Client], Prop_Send, "m_iUpgradeLevel",3);
	SetEntProp(AmplifierEnt[Client], Prop_Send, "m_nSkin", GetEntProp(AmplifierEnt[Client], Prop_Send, "m_nSkin")-2);
	if (AmplifierTeam[Client]==0)
		AttachParticle(AmplifierEnt[Client],"teleported_red",TPPar[Client]); //Create Effect of TP
	else
		AttachParticle(AmplifierEnt[Client],"teleported_blue",TPPar[Client]); //Create Effect of TP
	CreateTimer(2.0, DispCheckStage1a, Client);
	return Plugin_Continue;
}
//Wait for kill teleport effect
public Action:DispCheckStage1a(Handle:hTimer,any:Client)
{
	new String:str[255];
	if (IsValidEntity(TPPar[Client]))
	{
		GetEdictClassname(TPPar[Client], str, sizeof(str));
		if (StrEqual(str, "info_particle_system", false))
			RemoveEdict(TPPar[Client]);
	}
	TPPar[Client]=0;
	return Plugin_Continue;
}
//Spa suppin' mah Amplifier!!!!11
public CheckSapper(object, ent, userid)
{
	CreateTimer(0.5, SapperCheckStage1,ent);	
	//return Plugin_Continue;
}

public Action:SapperCheckStage1(Handle:hTimer,any:ent)
{
	new String:classname[64];
	GetEdictClassname(ent, classname, sizeof(classname));
	if (!strcmp(classname, "obj_attachment_sapper"))
	{
		for (new i=1;i<MP;i++)
		{
			if (AmplifierEnt[i]!=0)
			{
				if ((GetEntProp(AmplifierEnt[i], Prop_Send, "m_bHasSapper")==1) && !AmplifierSapped[i])
				{
					AmplifierSapped[i]=true;
					CreateTimer(0.2, SapperCheckStage2,i,TIMER_REPEAT);
					break;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:SapperCheckStage2(Handle:hTimer,any:i)
{
	if (!IsValidEntity(AmplifierEnt[i]) || (AmplifierEnt[i]==0) || ((GetEntProp(AmplifierEnt[i], Prop_Send, "m_bHasSapper")==0) && AmplifierSapped[i]))
	{
		AmplifierSapped[i]=false;
		if ((AmplifierEnt[i]!=0) && IsValidEntity(AmplifierEnt[i]))
			SetEntProp(AmplifierEnt[i], Prop_Send, "m_bDisabled", 1);
		KillTimer(hTimer);
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

Float:calcDistance(Float:x1,Float:x2,Float:y1,Float:y2,Float:z1,Float:z2){ 
	new Float:dx = x1-x2;
	new Float:dy = y1-y2;
	new Float:dz = z1-z2;
	return(SquareRoot(dx*dx + dy*dy + dz*dz));
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

stock bool:TF2_IsPlayerDisguised(client)
{
    new pcond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
    return pcond >= 0 ? ((pcond & (1 << 3)) != 0) : false;
}

