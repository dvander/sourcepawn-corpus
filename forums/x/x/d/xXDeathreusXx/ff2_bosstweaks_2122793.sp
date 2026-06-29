#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

new Float:g_headscale = 0.0;
new g_footsteps[MAXPLAYERS + 1];
new g_footstepsdb= 0;
new g_boss;
new String:g_leftfoot[PLATFORM_MAX_PATH];
new String:g_rightfoot[PLATFORM_MAX_PATH];
new bool:g_bHitboxAvailable = false;
new bool:g_bIsTF2 = false;
new Float:g_fClientCurrentScale[MAXPLAYERS+1] = {1.0, ... };

public Plugin:myinfo = {
	name = "Freak Fortress 2: Boss Tweaks",
	author = "jasonfrog, edit by Deathreus, code snippet from 11530",
	version = "1.2",
};

public OnMapStart()
{
	new String:sound[38];
	for (new x = 1 ; x < 18 ; x++) 
	{
		Format(sound, sizeof(sound), "mvm/player/footsteps/robostep_%s%i.wav", (x < 10) ? "0" : "", x);
		PrecacheSound(sound, true);
	}
	PrecacheSound("player/footsteps/giant1.wav", true);
	PrecacheSound("player/footsteps/giant2.wav", true);
	PrecacheSound("player/footsteps/mud1.wav", true);
	PrecacheSound("player/footsteps/mud2.wav", true);
	PrecacheSound("player/footsteps/mud3.wav", true);
	PrecacheSound("player/footsteps/mud4.wav", true);
}

public OnPluginStart2()
{
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
	AddNormalSoundHook(SoundHook);
	g_bHitboxAvailable = ((FindSendPropOffs("CBasePlayer", "m_vecSpecifiedSurroundingMins") != -1) && FindSendPropOffs("CBasePlayer", "m_vecSpecifiedSurroundingMaxs") != -1);
	decl String:szDir[64];
	GetGameFolderName(szDir, sizeof(szDir));
	if (strcmp(szDir, "tf") == 0 || strcmp(szDir, "tf_beta") == 0)
		g_bIsTF2 = true;
}

public OnClientConnected(client)
{
	g_footsteps[client] = 0;
	g_fClientCurrentScale[client] = 1.0;
}

public OnClientDisconnect(client)
{
	g_footsteps[client] = 0;
	g_fClientCurrentScale[client] = 1.0;
}

public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_headscale = 0.0;
	
	if (FF2_IsFF2Enabled())
	{
		g_boss = GetClientOfUserId(FF2_GetBossUserId(0));
		
		if (g_boss>0)
		{   			
			if (FF2_HasAbility(0, this_plugin_name, "scalemodel"))
			{
				new Float:scale = FF2_GetAbilityArgumentFloat(0, this_plugin_name, "scalemodel", 1);	       	 	//scale
				
				if (scale > 0) 
				{
					SetEntPropFloat(g_boss, Prop_Send, "m_flModelScale", scale);
					g_fClientCurrentScale[g_boss] = scale;
				}
				else if (scale == -1.0)
				{
					SetEntPropFloat(g_boss, Prop_Send, "m_flModelScale", (GetURandomFloat()*(1.3-0.7))+0.7);
					g_fClientCurrentScale[g_boss] = scale;
				}
				
				if (g_bHitboxAvailable)
				{
					UpdatePlayerHitbox(g_boss);
				}
			}
			
			if (FF2_HasAbility(0,this_plugin_name,"scalehead"))
			{
				new Float:scale = FF2_GetAbilityArgumentFloat(0, this_plugin_name, "scalehead", 1);	        	//scale
				if (scale > 0) 
				{
					g_headscale = scale;
				}
				else if (scale == -1.0)
				{
					g_headscale = (GetURandomFloat()*(4.0-0.5))+0.5;
				}
			}
			
			if (FF2_HasAbility(0,this_plugin_name,"footsteps"))
			{
				new type = FF2_GetAbilityArgument(0, this_plugin_name, "footsteps", 1);	        			//type
				if (type > 3 || type < -1) 
				{
					type = 0;
				}
				g_footstepsdb= FF2_GetAbilityArgument(0, this_plugin_name, "footsteps", 2);	        	//volume
				g_footsteps[g_boss] = type;
				if (type == -1) 
				{
					FF2_GetAbilityArgumentString(g_boss, this_plugin_name, "footsteps", 3, g_rightfoot, PLATFORM_MAX_PATH);
					FF2_GetAbilityArgumentString(g_boss, this_plugin_name, "footsteps", 4, g_leftfoot, PLATFORM_MAX_PATH);
					PrecacheSound(g_rightfoot, true);
					PrecacheSound(g_leftfoot, true);
				}
			}
			
			if (FF2_HasAbility(0,this_plugin_name,"colour"))
			{
				new r = FF2_GetAbilityArgument(0, this_plugin_name, "colour", 1);	        			//red (0-255)
				new g = FF2_GetAbilityArgument(0, this_plugin_name, "colour", 2);	        			//green (0-255)
				new b = FF2_GetAbilityArgument(0, this_plugin_name, "colour", 3);					//blue (0-255)
				if (r == -1)
				{
					r = GetRandomInt(0, 255);
				}
				if (g == -1)
				{
					g = GetRandomInt(0, 255);
				}
				if (b == -1)
				{
					b = GetRandomInt(0, 255);
				}
				SetEntityRenderColor(g_boss, r, g, b, 192);
			}
			
			if (FF2_HasAbility(0,this_plugin_name,"alpha"))
			{
				new a = FF2_GetAbilityArgument(0, this_plugin_name, "alpha", 1);					//alpha (0-255)
				if (a == -1)
				{
					a = GetRandomInt(0, 255);
				}
				SetEntityRenderColor(g_boss, _, _, _, a);
			}
			
			if (FF2_HasAbility(0,this_plugin_name,"gravity"))
			{
				new Float:gravity = FF2_GetAbilityArgumentFloat(0, this_plugin_name, "gravity", 1);	        	//gravity (0.1 very low, 8.0 very high, (1.0 normal)) 
				if (gravity < 0.0)
				{
					gravity = 0.0;
				}
				SetEntityGravity(g_boss, gravity);
			}
			
			if (FF2_HasAbility(0,this_plugin_name,"message"))
			{
				new type = FF2_GetAbilityArgument(0, this_plugin_name, "message", 1);	        			//type
				new delay = FF2_GetAbilityArgument(0, this_plugin_name, "message", 2);	        			//delay
				new String:message[PLATFORM_MAX_PATH];
				FF2_GetAbilityArgumentString(g_boss, this_plugin_name,"message", 3, message, PLATFORM_MAX_PATH);	//message
				
				new Handle:pack = CreateDataPack();
				CreateDataTimer(float(delay), ShowMessage, pack);
				WritePackCell(pack, type);
				WritePackString(pack, message);
				ResetPack(pack);
			}			
		}
	}
}

public Action:ShowMessage(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new type = ReadPackCell(pack);
	new String:message[PLATFORM_MAX_PATH];
	ReadPackString(pack, message, sizeof(message));
	switch (type)
	{
		case 0:
		{
			PrintToChatAll(message);
		}
		case 1:
		{
			PrintHintTextToAll(message);
		}
		case 2:
		{
			PrintCenterTextAll(message);
		}
	}
}

public Action:SoundHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &Ent, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (volume == 0.0 || volume == 0.9997) return Plugin_Continue;
	if (!IsValidClient(Ent)) return Plugin_Continue;
	new client = Ent;
	
	switch (g_footsteps[client])
	{
		case 0:
		{
			return Plugin_Continue;
		}
		case -1: // Custom footsteps
		{
			if (strncmp(sound, "player/footsteps/", 17, false) == 0)
			{
				StopSound(Ent, SNDCHAN_AUTO, sound);
				if (StrContains(sound, "1.wav", false) != -1 || StrContains(sound, "3.wav", false) != -1)
				{
					sound = g_leftfoot;
				}
				else if (StrContains(sound, "2.wav", false) != -1 || StrContains(sound, "4.wav", false) != -1)
				{
					sound = g_rightfoot;
				}
				if (g_footstepsdb> 0)
				{
					EmitSoundToAll(sound, client, _, g_footstepsdb);
				} else {
					EmitSoundToAll(sound, client);
				}
				return Plugin_Changed;
			}		
		}
		case 1:	//Giant footsteps
		{
			if (strncmp(sound, "player/footsteps/", 17, false) == 0)
			{
				StopSound(Ent, SNDCHAN_AUTO, sound);
				if (StrContains(sound, "1.wav", false) != -1 || StrContains(sound, "3.wav", false) != -1)
				{
					sound = "player/footsteps/giant1.wav";
				}
				else if (StrContains(sound, "2.wav", false) != -1 || StrContains(sound, "4.wav", false) != -1)
				{
					sound = "player/footsteps/giant2.wav";
				}
				if (g_footstepsdb> 0)
				{
					EmitSoundToAll(sound, client, _, g_footstepsdb);
				} else {
					EmitSoundToAll(sound, client, _, 150);
				}
				return Plugin_Changed;
			}
		}
		case 2:	//Robot footsteps		
		{
			StopSound(Ent, SNDCHAN_AUTO, sound);
			if (strncmp(sound, "player/footsteps/", 17, false) == 0)
			{
				new rand = GetRandomInt(1,18);
				Format(sound, sizeof(sound), "mvm/player/footsteps/robostep_%s%i.wav", (rand < 10) ? "0" : "", rand);
				if (g_footstepsdb> 0)
				{
					EmitSoundToAll(sound, client, _, g_footstepsdb);
				} else {
					EmitSoundToAll(sound, client);
				}
				return Plugin_Changed;
			}
		}
		case 3:	//Squelchy footsteps
		{
			if (strncmp(sound, "player/footsteps/", 17, false) == 0)
			{
				StopSound(Ent, SNDCHAN_AUTO, sound);
				if (StrContains(sound, "1.wav", false) != -1)
				{
					sound = "player/footsteps/mud1.wav";
				}
				if (StrContains(sound, "2.wav", false) != -1)
				{
					sound = "player/footsteps/mud2.wav";
				}
				if (StrContains(sound, "3.wav", false) != -1)
				{
					sound = "player/footsteps/mud3.wav";
				}
				if (StrContains(sound, "4.wav", false) != -1)
				{
					sound = "player/footsteps/mud4.wav";
				}
				if (g_footstepsdb> 0)
				{
					EmitSoundToAll(sound, client, _, g_footstepsdb);
				} else {
					EmitSoundToAll(sound, client);
				}
				return Plugin_Changed;
			}
		}	
	}
	return Plugin_Continue;
}

public OnGameFrame()
{
	if (g_headscale)
	{
		if(IsValidClient(g_boss))
		{
			SetEntPropFloat(g_boss, Prop_Send, "m_flHeadScale", g_headscale);
		}
	}
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsValidClient(g_boss))
	{
		SetEntPropFloat(g_boss, Prop_Send, "m_flModelScale", 1.0);
		g_footsteps[g_boss] = 0;
		SetEntityRenderColor(g_boss, 255, 255, 255, 255);
		SetEntityGravity(g_boss, 1.0);
	}
	g_headscale = 0.0;
	g_fClientCurrentScale[g_boss] = 1.0;
	UpdatePlayerHitbox(g_boss);
	
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}

stock UpdatePlayerHitbox(const client)
{
	static const Float:vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 }, Float:vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 };
	static const Float:vecGenericPlayerMin[3] = { -16.5, -16.5, 0.0 }, Float:vecGenericPlayerMax[3] = { 16.5,  16.5, 73.0 };
	decl Float:vecScaledPlayerMin[3], Float:vecScaledPlayerMax[3];
	if (g_bIsTF2)
	{
		vecScaledPlayerMin = vecTF2PlayerMin;
		vecScaledPlayerMax = vecTF2PlayerMax;
	}
	else
	{
		vecScaledPlayerMin = vecGenericPlayerMin;
		vecScaledPlayerMax = vecGenericPlayerMax;
	}
	ScaleVector(vecScaledPlayerMin, g_fClientCurrentScale[client]);
	ScaleVector(vecScaledPlayerMax, g_fClientCurrentScale[client]);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
}



