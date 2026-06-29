//===EqestriaGirls Dispenser===
//Dispenser has Main Six Equestria Girls on Screen and Music from MLP: EG Movies Soundtrack.

#define ME 2048
#define MP 34

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <colors>

//#undef REQUIRE_PLUGIN 
//#tryinclude <floral_defence>

new PonyRef[ME][MP];
new LastMusic[ME][MP];
new Float:nextsong[ME][MP];
new Float:DispenserPos[ME][3];
new bool:bIsEnabled[ME];
new bool:bPony[MP];

//new bool:FD_Enabled;

new Handle:OnMusic = INVALID_HANDLE;

new String:Music[][PLATFORM_MAX_PATH]=
{
	"egdispenser\\better_than_ever.mp3",
	"egdispenser\\cafeteria_song_v2.mp3",
	"egdispenser\\shake_your_tail.mp3",
	"egdispenser\\this_is_our_big_night_v2.mp3",
	"egdispenser\\time_to_come_together_v2.mp3",
	
	"egdispenser\\shake_your_tail.mp3",
	"egdispenser\\time_to_come_together_v2.mp3",
	"egdispenser\\this_is_our_big_night_v2.mp3",
	"egdispenser\\better_than_ever.mp3",
	"egdispenser\\cafeteria_song_v2.mp3",
	
	"egdispenser\\shake_your_tail.mp3",
	"egdispenser\\this_is_our_big_night_v2.mp3",
	"egdispenser\\better_than_ever.mp3",
	"egdispenser\\cafeteria_song_v2.mp3",
	"egdispenser\\time_to_come_together_v2.mp3"
	
};

new Float:MusicTime[]={95.0,174.0,119.0,123.0,127.0,119.0,127.0,123.0,95.0,174.0,119.0,123.0,95.0,174.0,127.0};

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = {
	name = "EquestriaGirls Dispenser",
	author = "RainBolt Dash, Bonkorn",
	description = "Dispenser has Main Six Equestria Girls on Screen and Music from MLP: EG Movies Soundtrack.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=273159"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	//forward OnPonyspenserMusic(client, String:path[],&Float:time);
	OnMusic=CreateGlobalForward("OnPonyspenserMusic",ET_Hook,Param_Cell,Param_String, Param_FloatByRef);
	return APLRes_Success;
}

public OnPluginStart()
{			
	//FD_Enabled=LibraryExists("floral_defence");
	CreateConVar("egd_version", PLUGIN_VERSION, "Version of Equestria Girls Dispenser Plugin", FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("player_builtobject", event_build);
	HookEvent("teamplay_round_start", event_round_start);
	HookEvent("player_spawn", event_player_spawn);
	HookEvent("object_removed", event_destroy);
	HookEvent("object_destroyed", event_destroy);
	
	RegConsoleCmd("eg", SelectPony);
	RegConsoleCmd("sm_eg", SelectPony);
	for(new client = 1; client <= MaxClients; client++)
		if (IsValidEdict(client) && IsClientConnected(client))
			OnClientPutInServer(client);
}
/*
public OnLibraryAdded(const String:name[])
{
	if (!strcmp(name,"floral_defence"))
		FD_Enabled=true;
}

public OnLibraryRemoved(const String:name[])
{
	if (!strcmp(name,"floral_defence"))
		FD_Enabled=false;
}
*/

public OnMapStart()
{	
	decl i;
	decl String:s[PLATFORM_MAX_PATH];
	for(i=0;i<=05;i++)
	{
		Format(s,PLATFORM_MAX_PATH,"materials\\custom\\egdispenser0%i_v2.vtf",i);
		AddFileToDownloadsTable(s);
		Format(s,PLATFORM_MAX_PATH,"materials\\custom\\egdispenser0%i_v2.vmt",i);
		AddFileToDownloadsTable(s);
	}
	AddFileToDownloadsTable("models\\custom\\the_egdispenser_v3.mdl");
	AddFileToDownloadsTable("models\\custom\\the_egdispenser_v3.dx80.vtx");
	AddFileToDownloadsTable("models\\custom\\the_egdispenser_v3.dx90.vtx");
	AddFileToDownloadsTable("models\\custom\\the_egdispenser_v3.sw.vtx");
	AddFileToDownloadsTable("models\\custom\\the_egdispenser_v3.vvd");
	PrecacheModel("models\\custom\\the_egdispenser_v3.mdl",true);	
	/*if (FD_Enabled)
	{
		AddFileToDownloadsTable("models\\custom\\the_egdispenser_1_v3.mdl");
		AddFileToDownloadsTable("models\\custom\\the_egdispenser_1_v3.dx80.vtx");
		AddFileToDownloadsTable("models\\custom\\the_egdispenser_1_v3.dx90.vtx");
		AddFileToDownloadsTable("models\\custom\\the_egdispenser_1_v3.sw.vtx");
		AddFileToDownloadsTable("models\\custom\\the_egdispenser_1_v3.vvd");
		PrecacheModel("models\\custom\\the_egdispenser_1_v3.mdl",true);	
	}*/
	
	AddFileToDownloadsTable("materials\\custom\\egdispenser_info_v2.vmt");
	AddFileToDownloadsTable("materials\\custom\\egdispenser_info_v2.vtf");

	new see=sizeof(Music);
	PrecacheSound("replay/showdetails.wav");
	for(i=0;i<see;i++)
	{
		PrecacheSound(Music[i],true);
		Format(s,PLATFORM_MAX_PATH,"sound\\%s",Music[i]);
		AddFileToDownloadsTable(s);
	}
}

public OnClientPutInServer(client)
{
	for(new ent=MaxClients+1;ent<ME;ent++)
		nextsong[ent][client]=0.0;
		
	decl String:path[PLATFORM_MAX_PATH];
	decl String:s[64];
	BuildPath(Path_SM,path,PLATFORM_MAX_PATH,"configs/egdispenser_list.cfg");
	new Handle:kv = CreateKeyValues("egdispenser_list");
	FileToKeyValues(kv, path);
	bPony[client]=bool:KvGetNum(kv,s,0);
	CloseHandle(kv);
}

public Action:event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	if (!bPony[client] && TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		if (GetClientTeam(client)==2)
			DoOverlay(client,"custom\\egdispenser_info_v2");
		else
			DoOverlay(client,"custom\\egdispenser_info_v2");
		CreateTimer(15.0,Timer_RemoveInfo,GetClientUserId(client));
	}
	return Plugin_Continue;
}

public Action:Timer_RemoveInfo(Handle:hTimer,any:clientid)
{
	new client=GetClientOfUserId(clientid);
	if (client)
		DoOverlay(client,"");
	return Plugin_Continue;
}

public Action:SelectPony(client, Args)
{
	bPony[client]=!bPony[client];
	if (bPony[client])
		CPrintToChat(client,"{olive}[SM]{default} Now you will build a EquestriaGirls Dispenser!");
	else
		CPrintToChat(client,"{olive}[SM]{default} Now you will build a Normal Dispenser!");
	decl String:path[PLATFORM_MAX_PATH];
	decl String:s[64];
	BuildPath(Path_SM,path,PLATFORM_MAX_PATH,"configs/egdispenser_list.cfg");
	new Handle:kv = CreateKeyValues("egdispenser_list");
	FileToKeyValues(kv, path);
	if (bPony[client])
		KvSetNum(kv,s,1);
	else
		KvSetNum(kv,s,0);
	KeyValuesToFile(kv, path);
	CloseHandle(kv);	
	return Plugin_Handled;	
}

public Action:event_build(Handle:event, const String:name[], bool:dontBroadcast)
{
	new ent=GetEventInt(event, "index");
	new client=GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
	if (client<1 || !bPony[client])
		return Plugin_Continue;
	CreateTimer(0.01, Timer_CheckDisp, ent,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	decl Float:pos[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);	
	DispenserPos[ent][0]=RoundFloat(pos[0])*1.0;
	DispenserPos[ent][1]=RoundFloat(pos[1])*1.0;
	DispenserPos[ent][2]=RoundFloat(pos[2])*1.0;
	for(new i=1;i<=MaxClients;i++)
		nextsong[ent][i]=0.0;
	bIsEnabled[ent]=false;	
	return Plugin_Continue;
}

public Action:event_destroy(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new ent=GetEventInt(event, "index");
	new client=GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
	if (client>0 && bPony[client] && !GetEventInt(event, "objecttype"))
	{
		decl pony;
		new see=sizeof(Music);
		for(client=1;client<=MaxClients;client++)
		{
			pony=EntRefToEntIndex(PonyRef[ent][client]);
			if (pony && IsValidEdict(pony))
			{				
				if (LastMusic[ent][client]>=0 && LastMusic[ent][client]<see)
				{
					StopSound(pony,SNDCHAN_USER_BASE+24,Music[LastMusic[ent][client]]);
					StopSound(pony,SNDCHAN_USER_BASE+22,Music[LastMusic[ent][client]]);
					StopSound(pony,SNDCHAN_USER_BASE+23,Music[LastMusic[ent][client]]);
				}
				CreateTimer(0.0,RemoveEnt,PonyRef[ent][client]);
				PonyRef[ent][client]=0;
			}
		}	
	}
	return Plugin_Continue;
}

public Action:Timer_CheckDisp(Handle:hTimer,any:ent)
{
	if (!ZeIsValidEdict(ent,"obj_dispenser") || GetEntProp(ent, Prop_Send, "m_bPlacing"))
	{
		decl pony;
		new see=sizeof(Music);
		for(new client=1;client<=MaxClients;client++)
		{
			pony=EntRefToEntIndex(PonyRef[ent][client]);
			if (pony && IsValidEdict(pony))
			{				
				if (LastMusic[ent][client]>=0 && LastMusic[ent][client]<see)
				{
					StopSound(pony,SNDCHAN_USER_BASE+24,Music[LastMusic[ent][client]]);
					StopSound(pony,SNDCHAN_USER_BASE+22,Music[LastMusic[ent][client]]);
					StopSound(pony,SNDCHAN_USER_BASE+23,Music[LastMusic[ent][client]]);
				}
				CreateTimer(0.0,RemoveEnt,PonyRef[ent][client]);
				PonyRef[ent][client]=0;
			}
		}
		if (bIsEnabled[ent])
		{
			new pony2=-1;
			decl client;
			while ((pony2 = FindEntityByClassname(pony2, "obj_dispenser")) != -1)
				if ((pony2!=ent) && !bIsEnabled[pony2] && GetVectorDistance(DispenserPos[ent],DispenserPos[pony2])<750)
					for(client=1;client<=MaxClients;client++)
						if (IsValidEdict(client))
						{
							nextsong[pony2][client]=10.0;
							new Handle:data;
							CreateDataTimer(0.1, Timer_EnablePony, data);
							WritePackCell(data, EntIndexToEntRef(pony2));
							WritePackCell(data, GetClientUserId(client));
							ResetPack(data);
						}
		}
		bIsEnabled[ent]=false;
		return Plugin_Stop;
	}
	else if (GetEntPropFloat(ent, Prop_Send, "m_flPercentageConstructed")==1.00)
	{
		decl Float:pos[3];
		decl Float:distance;
		for(new client=1;client<=MaxClients;client++)
		if (IsValidEdict(client) && IsClientConnected(client))
		{
			if (nextsong[ent][client]<=0.0)
			{
				nextsong[ent][client]=10.0;
				new Handle:data;
				CreateDataTimer(0.1, Timer_EnablePony, data);
				WritePackCell(data, EntIndexToEntRef(ent));
				WritePackCell(data, GetClientUserId(client));
				ResetPack(data);
			}
			else
			{
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
				distance=GetVectorDistance(pos,DispenserPos[ent]);
				if (nextsong[ent][client]<999.0)
				{	
					if (distance>=1500.0)
						nextsong[ent][client]=1000.0;
					else
						nextsong[ent][client]-=0.1;
				}
				else if (distance<1500.0)
					nextsong[ent][client]=0.0;
			}
		}
	}
	return Plugin_Continue;
}

//Check for Amplifier, Beespenser, Repair node etc.
public Action:Timer_EnablePony(Handle:hTimer,Handle:data)
{
	new ent=EntRefToEntIndex(ReadPackCell(data));
	if (ent==-1)
		return Plugin_Continue;
	new client=GetClientOfUserId(ReadPackCell(data));
	new owner=GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
	if (owner<1 || !bPony[owner])
		return Plugin_Continue;
	/*decl bool:usefd;
	if (!FD_Enabled)
		usefd=false;
	else
		usefd=FD_IsUseFD(owner);*/
	if (ent>0 && client && (!GetEntProp(ent, Prop_Send, "m_bDisabled")/* || usefd*/))
	{
		decl pony;
		decl Float:pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);	
		pos[0]=RoundFloat(pos[0])*1.0;
		pos[1]=RoundFloat(pos[1])*1.0;
		pos[2]=RoundFloat(pos[2])*1.0;
		new random=GetRandomInt(0,10);
		decl Float:rot[3];
		GetEntPropVector(ent, Prop_Send, "m_angRotation", rot);	
		TeleportEntity(ent, pos, rot, NULL_VECTOR);		
		
		if (EntRefToEntIndex(PonyRef[ent][client])<=MaxClients)
			pony = CreateEntityByName("prop_dynamic");
		else
			pony = EntRefToEntIndex(PonyRef[ent][client]);
		/*if (!usefd)
		{
			TeleportEntity(pony, pos, rot, NULL_VECTOR);
			SetEntityModel(pony,"models\\custom\\the_egdispenser_v3.mdl");
		}
		else
		{
			pos[0]+=5;
			TeleportEntity(pony, pos, NULL_VECTOR, NULL_VECTOR);
			SetEntityModel(pony,"models\\custom\\the_egdispenser_1_v3.mdl");
			SetVariantString("!activator");
			AcceptEntityInput(pony, "SetParent",ent);
			SetVariantString("head");
			AcceptEntityInput(pony, "SetParentAttachment");
		}*/
		TeleportEntity(pony, pos, rot, NULL_VECTOR);
		SetEntityModel(pony,"models\\custom\\the_egdispenser_v3.mdl");
			
		SetEntPropEnt(pony, Prop_Data, "m_hOwnerEntity",client); 
		SetEntProp(pony, Prop_Send, "m_nSkin",random);	
		PonyRef[ent][client]=EntIndexToEntRef(pony);
			
		SDKHook(pony, SDKHook_SetTransmit, Hook_SetTransmit);	
		if (LastMusic[ent][client]>=0 && LastMusic[ent][client]<sizeof(Music))
		{
			StopSound(pony,SNDCHAN_USER_BASE+24,Music[LastMusic[ent][client]]);
			StopSound(pony,SNDCHAN_USER_BASE+22,Music[LastMusic[ent][client]]);
			StopSound(pony,SNDCHAN_USER_BASE+23,Music[LastMusic[ent][client]]);			
		}
		if (!bIsEnabled[ent])
		{
			bIsEnabled[ent]=true;
			new pony2=-1;
			while ((pony2 = FindEntityByClassname(pony2, "obj_dispenser")) != -1)
				if ((pony2!=ent) && bIsEnabled[pony2] && (GetVectorDistance(DispenserPos[ent],DispenserPos[pony2])<750))				
				{
					bIsEnabled[pony2]=true;
					bIsEnabled[ent]=false;
					return Plugin_Continue;		
				}
		}
		if ((random!=1) && (random!=4) && (random!=5) && (random!=8) && (random!=10))
		{
			random=GetRandomInt(0,sizeof(Music)-1);
			while ((random==1) || (random==4) || (random==5) || (random==8) || (random==9))
				random=GetRandomInt(0,sizeof(Music)-1);
		}		
		LastMusic[ent][client]=random;
		
		new Action:act = Plugin_Continue;
		Call_StartForward(OnMusic);
		Call_PushCell(client);
		decl String:sound2[PLATFORM_MAX_PATH];
		new Float:time2 = MusicTime[random];
		strcopy(sound2, PLATFORM_MAX_PATH, Music[random]);
		Call_PushStringEx(sound2, PLATFORM_MAX_PATH, 0, SM_PARAM_COPYBACK);
		Call_PushFloatRef(time2);
		Call_Finish(act);
		switch (act)
		{
			case Plugin_Changed:
			{
				nextsong[ent][client] = time2;
				if (sound2[0])
				{
					EmitSoundToClient(client,sound2,pony,SNDCHAN_USER_BASE+24,_,_,_,_,pony,pos);
					EmitSoundToClient(client,sound2,pony,SNDCHAN_USER_BASE+22,_,_,_,_,pony,pos);
					EmitSoundToClient(client,sound2,pony,SNDCHAN_USER_BASE+23,_,_,_,_,pony,pos);
				}
			}
			case Plugin_Continue:
			{
				EmitSoundToClient(client,Music[random],pony,SNDCHAN_USER_BASE+24,_,_,_,_,pony,pos);
				EmitSoundToClient(client,Music[random],pony,SNDCHAN_USER_BASE+22,_,_,_,_,pony,pos);
				EmitSoundToClient(client,Music[random],pony,SNDCHAN_USER_BASE+23,_,_,_,_,pony,pos);
			}
		}
		nextsong[ent][client]=MusicTime[random];
	}
	return Plugin_Continue;
}

public Action:Hook_SetTransmit(entity, client)
{
	if (GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity")==client)
		return Plugin_Continue;
	return Plugin_Handled;
}  

public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl client,pony;
	for(new ent=0;ent<ME;ent++)
		for(client=1;client<=MaxClients;client++)
		{
			pony=EntRefToEntIndex(PonyRef[ent][client]);				
			if (pony && IsValidEdict(pony))
			{				
				EmitSoundToClient(client,"replay/showdetails.wav",pony,SNDCHAN_USER_BASE+22,_,_,_,_,pony);
				EmitSoundToClient(client,"replay/showdetails.wav",pony,SNDCHAN_USER_BASE+23,_,_,_,_,pony);
				EmitSoundToClient(client,"replay/showdetails.wav",pony,SNDCHAN_USER_BASE+24,_,_,_,_,pony);
				CreateTimer(0.0,RemoveEnt,PonyRef[ent][client]);
				PonyRef[ent][client]=0;
			}
		}	
}

stock ZeIsValidEdict(edict,String:class[]="0")
{
	if (edict && IsValidEdict(edict))
	{
		decl String:s[64];
		GetEdictClassname(edict, s, 64);
		if ((!StrEqual(s, "instanced_scripted_scene") && (class[0]=='0')) || StrEqual(class,s))			
			return true;
	}
	return false;
}

DoOverlay(client, const String:overlay[])
{	
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT));
	ClientCommand(client, "r_screenoverlay \"%s\"", overlay);
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
}

public Action:RemoveEnt(Handle:timer, any:entid)
{
	new ent=EntRefToEntIndex(entid);
	if (IsValidEntity(ent) && ent)
		AcceptEntityInput(ent, "Kill");
	return Plugin_Continue;
}