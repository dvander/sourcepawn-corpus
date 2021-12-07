#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0 Release"

new Float:g_Position[3];

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public Plugin:myinfo =
{
	name = "[TF2] Merasmus Spawner",
	author = "Tak (Chaosxk)",
	description = "RUN COWARDS! RUN!!!",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_merasmus_version", PLUGIN_VERSION, "Version of Merasmus Spawner", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	RegAdminCmd("sm_merasmus", MerasmusCmd, ADMFLAG_GENERIC, "Spawn Merasmus at player eye position");
	RegAdminCmd("sm_meras", MerasmusCmd, ADMFLAG_GENERIC, "Spawn Merasmus at player eye position");

	RegAdminCmd("sm_slaymeras", SlayMerasmusCmd, ADMFLAG_GENERIC, "Kill Merasmus");
}

public OnMapStart()
{
	CacheFiles();
}

public Action:SlayMerasmusCmd(client, args)
{
	if(!IsValidClient(client)) return Plugin_Continue;

	new ent = -1;
	while((ent = FindEntityByClassname(ent, "merasmus")) != -1 && IsValidEntity(ent))
	{
		new Handle:g_Event = CreateEvent("merasmus_killed", true);
		FireEvent(g_Event);
		AcceptEntityInput(ent, "Kill");
	}

	return Plugin_Continue;
}

public Action:MerasmusCmd(client, args)
{
	if(!IsValidClient(client)) return Plugin_Continue;

	if(GetEntityCount() >= GetMaxEntities()-32)
	{
		ReplyToCommand(client, "[SM] Too many valid entities on map.");
		return Plugin_Handled;
	}
	
	if(!SetTeleportEndPoint(client))
	{
		ReplyToCommand(client, "[SM] Could not find spawn point.");
		return Plugin_Handled;
	}

	new ent = CreateEntityByName("merasmus");
	if(!IsValidEntity(ent))
	{
		ReplyToCommand(client, "[SM] Error spawning Merasmus.");
		return Plugin_Handled;
	}

	DispatchSpawn(ent);
	g_Position[2] -= 10.0;
	TeleportEntity(ent, g_Position, NULL_VECTOR, NULL_VECTOR);

	return Plugin_Handled;
}

stock bool:IsValidClient(i, bool:replay = true)
{
	if(i <= 0 || i > MaxClients || !IsClientInGame(i)) return false;
	if(replay && (IsClientSourceTV(i) || IsClientReplay(i))) return false;
	return true;
}

stock bool:SetTeleportEndPoint(client)
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;

	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
		GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_Position[0] = vStart[0] + (vBuffer[0]*Distance);
		g_Position[1] = vStart[1] + (vBuffer[1]*Distance);
		g_Position[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else
	{
		CloseHandle(trace);
		return false;
	}
	CloseHandle(trace);
	return true;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}

CacheFiles()
{
	PrecacheModel("models/bots/merasmus/merasmus.mdl");
	PrecacheModel("models/prop_lakeside_event/bomb_temp.mdl");
	PrecacheModel("models/prop_lakeside_event/bomb_temp_hat.mdl");

	PrecacheSound("vo/halloween_merasmus/sf12_appears01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_appears02.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_appears03.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_appears04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_appears07.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_appears09.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_appears10.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_appears11.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_appears13.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_appears14.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_appears15.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_appears16.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_appears17.wav");

	PrecacheSound("vo/halloween_merasmus/sf12_attacks01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_attacks03.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_attacks04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_attacks05.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_attacks06.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_attacks07.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_attacks08.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_attacks09.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_attacks10.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_attacks11.wav");

	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb02.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb03.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb08.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb09.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb10.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb13.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb14.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb17.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb19.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb23.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb24.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb25.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb26.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb28.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb29.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb30.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb31.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb32.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb33.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb34.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb35.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb36.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb37.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb38.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb39.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb40.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb41.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb42.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb44.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb45.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb46.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb47.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb48.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb49.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb50.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb51.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb52.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb53.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb54.wav");

	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up05.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up06.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up07.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up08.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up10.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up11.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up12.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up13.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up14.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up15.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up17.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up18.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up19.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up20.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up21.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up24.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up25.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up27.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up28.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up29.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up30.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up31.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up32.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up33.wav");

	PrecacheSound("vo/halloween_merasmus/sf12_bcon_island02.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_island03.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_island04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_skullhat01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_skullhat02.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_skullhat03.wav");

	PrecacheSound("vo/halloween_merasmus/sf12_combat_idle01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_combat_idle02.wav");

	PrecacheSound("vo/halloween_merasmus/sf12_defeated01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_defeated02.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_defeated03.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_defeated04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_defeated05.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_defeated06.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_defeated07.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_defeated08.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_defeated09.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_defeated10.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_defeated11.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_defeated12.wav");

	PrecacheSound("vo/halloween_merasmus/sf12_found01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_found02.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_found03.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_found04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_found05.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_found07.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_found08.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_found09.wav");

	PrecacheSound("vo/halloween_merasmus/sf12_grenades03.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_grenades04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_grenades05.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_grenades06.wav");

	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit02.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit03.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit05.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit06.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit07.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit08.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit09.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit10.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit12.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit13.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit14.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit15.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit16.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit17.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit18.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit19.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit20.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit21.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit23.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit24.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit25.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit26.wav");

	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal02.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal03.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal05.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal06.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal07.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal08.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal09.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal11.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal12.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal13.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal14.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal15.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal16.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal17.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal19.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles_demo01.wav");

	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles05.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles06.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles07.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles08.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles09.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles10.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles11.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles12.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles14.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles15.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles16.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles18.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles20.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles21.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles22.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles23.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles24.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles25.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles26.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles27.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles28.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles29.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles30.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles31.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles33.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles27.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles41.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles42.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles44.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles46.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles47.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles48.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles49.wav");

	PrecacheSound("vo/halloween_merasmus/sf12_leaving01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving02.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving03.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving05.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving06.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving07.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving08.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving09.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving10.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving11.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving12.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving13.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving16.wav");

	PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire06.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire07.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire23.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire29.wav");

	PrecacheSound("vo/halloween_merasmus/sf12_magicwords11.wav");

	PrecacheSound("vo/halloween_merasmus/sf12_pain01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_pain02.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_pain03.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_pain04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_pain05.wav");

	PrecacheSound("vo/halloween_merasmus/sf12_ranged_attack04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_ranged_attack05.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_ranged_attack06.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_ranged_attack07.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_ranged_attack08.wav");

	PrecacheSound("vo/halloween_merasmus/sf12_staff_magic02.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_staff_magic03.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_staff_magic04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_staff_magic05.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_staff_magic06.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_staff_magic08.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_staff_magic09.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_staff_magic10.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_staff_magic11.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_staff_magic12.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_staff_magic13.wav");
}