#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

new bool:canslap[MAXPLAYERS+1];
new bool:gotslapped[MAXPLAYERS+1];

new Handle:BoomerSlap_enabled = INVALID_HANDLE;
new Handle:BoomerSlapPower = INVALID_HANDLE;
new Handle:BoomerSlapCooldown = INVALID_HANDLE;
new Handle:BoomerSlapAnnounce = INVALID_HANDLE;
new Handle:BoomerSlappedTime = INVALID_HANDLE;

new Handle:SmokerSlap_enabled = INVALID_HANDLE;
new Handle:SmokerSlapPower = INVALID_HANDLE;
new Handle:SmokerSlapCooldown = INVALID_HANDLE;
new Handle:SmokerSlapAnnounce = INVALID_HANDLE;
new Handle:SmokerSlappedTime = INVALID_HANDLE;

new Handle:JockeySlap_enabled = INVALID_HANDLE;
new Handle:JockeySlapPower = INVALID_HANDLE;
new Handle:JockeySlapCooldown = INVALID_HANDLE;
new Handle:JockeySlapAnnounce = INVALID_HANDLE;
new Handle:JockeySlappedTime = INVALID_HANDLE;

new Handle:HunterSlap_enabled = INVALID_HANDLE;
new Handle:HunterSlapPower = INVALID_HANDLE;
new Handle:HunterSlapCooldown = INVALID_HANDLE;
new Handle:HunterSlapAnnounce = INVALID_HANDLE;
new Handle:HunterSlappedTime = INVALID_HANDLE;

new Handle:ChargerSlap_enabled = INVALID_HANDLE;
new Handle:ChargerSlapPower = INVALID_HANDLE;
new Handle:ChargerSlapCooldown = INVALID_HANDLE;
new Handle:ChargerSlapAnnounce = INVALID_HANDLE;
new Handle:ChargerSlappedTime = INVALID_HANDLE;

new Handle:SpitterSlap_enabled = INVALID_HANDLE;
new Handle:SpitterSlapPower = INVALID_HANDLE;
new Handle:SpitterSlapCooldown = INVALID_HANDLE;
new Handle:SpitterSlapAnnounce = INVALID_HANDLE;
new Handle:SpitterSlappedTime = INVALID_HANDLE;

new Handle:TankSlap_enabled = INVALID_HANDLE;
new Handle:TankSlapPower = INVALID_HANDLE;
new Handle:TankSlapCooldown = INVALID_HANDLE;
new Handle:TankSlapAnnounce = INVALID_HANDLE;
new Handle:TankSlappedTime = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "L4D2_Special Infectee Bitch Slap",
	author = " AtomicStryker & IxAvnoMonvAxI",
	description = "Left 4 Dead 2 Special Infectee Bitch Slap",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=97952"
}

public OnPluginStart()
{
	CreateConVar("l4d2_si_bitchslap_version", PLUGIN_VERSION, "플러그인의 버전은?", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	BoomerSlap_enabled = CreateConVar("l4d2_si_boomer_enabled","1", "부머의 후려치기 플러그인의 사용 여부는? (0: 사용 안 함 | 1: 사용함)", CVAR_FLAGS);
	BoomerSlapPower = CreateConVar("l4d2_si_boomer_power","150.0", "부머에게 후려치기를 당한 생존자는 얼마나 높이 날아가는가?", CVAR_FLAGS);
	BoomerSlapCooldown = CreateConVar("l4d2_si_boomer_cooldown","10.0", "부머의 후려치기의 지연 시간은?", CVAR_FLAGS);
	BoomerSlapAnnounce = CreateConVar("l4d2_si_boomer_announce","1", "부머의 메시지의 표시 여부는? (0: 표시 안 함 | 1: 표시함)", CVAR_FLAGS);
	BoomerSlappedTime = CreateConVar("l4d2_si_boomer_disabletime","3.0", "부머에게 후려치기를 당한 생존자는 얼마 동안 제약을 받는가?", CVAR_FLAGS);

	SmokerSlap_enabled = CreateConVar("l4d2_si_smoker_enabled","1", "스모커의 후려치기 플러그인의 사용 여부는? (0: 사용 안 함 | 1: 사용함)", CVAR_FLAGS);
	SmokerSlapPower = CreateConVar("l4d2_si_smoker_power","150.0", "스모커의 후려치기를 당한 생존자는 얼마나 높이 날아가는가?", CVAR_FLAGS);
	SmokerSlapCooldown = CreateConVar("l4d2_si_smoker_cooldown","10.0", "스모커의 후려치기의 지연 시간은?", CVAR_FLAGS);
	SmokerSlapAnnounce = CreateConVar("l4d2_si_smoker_announce","1", "스모커 메시지의 표시 여부는? (0: 표시 안 함 | 1: 표시함)", CVAR_FLAGS);
	SmokerSlappedTime = CreateConVar("l4d2_si_smoker_disabletime","3.0", "스모커에게 후려치기를 당한 생존자는 얼마 동안 제약을 받는가?", CVAR_FLAGS);

	JockeySlap_enabled = CreateConVar("l4d2_si_jockey_enabled","1", "자키의 후려치기 플러그인의 사용 여부는? (0: 사용 안 함 | 1: 사용함)", CVAR_FLAGS);
	JockeySlapPower = CreateConVar("l4d2_si_jockey_power","150.0", "자키에게 후려치기를 당한 생존자는 얼마나 높이 날아가는가?", CVAR_FLAGS);
	JockeySlapCooldown = CreateConVar("l4d2_si_jockey_cooldown","10.0", "자키의 후려치기의 지연 시간은?", CVAR_FLAGS);
	JockeySlapAnnounce = CreateConVar("l4d2_si_jockey_announce","1", "자키 메시지의 표시 여부는? (0: 표시 안 함 | 1: 표시함)", CVAR_FLAGS);
	JockeySlappedTime = CreateConVar("l4d2_si_jockey_disabletime","3.0", "자키에게 후려치기를 당한 생존자는 얼마 동안 제약을 받는가?", CVAR_FLAGS);

	HunterSlap_enabled = CreateConVar("l4d2_si_hunter_enabled","1", "헌터의 후려치기 플러그인의 사용 여부는? (0: 사용 안 함 | 1: 사용함)", CVAR_FLAGS);
	HunterSlapPower = CreateConVar("l4d2_si_hunter_power","150.0", "헌터의 후려치기를 당한 생존자는 얼마나 높이 날아가는가?", CVAR_FLAGS);
	HunterSlapCooldown = CreateConVar("l4d2_si_hunter_cooldown","10.0", "헌터의 후려치기의 지연 시간은?", CVAR_FLAGS);
	HunterSlapAnnounce = CreateConVar("l4d2_si_hunter_announce","1", "헌터 메시지의 표시 여부는? (0: 표시 안 함 | 1: 표시함)", CVAR_FLAGS);
	HunterSlappedTime = CreateConVar("l4d2_si_hunter_disabletime","3.0", "헌터에게 후려치기를 당한 생존자는 얼마 동안 제약을 받는가?", CVAR_FLAGS);

	ChargerSlap_enabled = CreateConVar("l4d2_si_charger_enabled","1", "차저의 후려치기 플러그인의 사용 여부는? (0: 사용 안 함 | 1: 사용함)", CVAR_FLAGS);
	ChargerSlapPower = CreateConVar("l4d2_si_charger_power","150.0", "차저에게 후려치기를 당한 생존자는 얼마나 높이 날아가는가?", CVAR_FLAGS);
	ChargerSlapCooldown = CreateConVar("l4d2_si_charger_cooldown","10.0", "차저의 후려치기의 지연 시간은?", CVAR_FLAGS);
	ChargerSlapAnnounce = CreateConVar("l4d2_si_charger_announce","1", "차저 메시지의 표시 여부는? (0: 표시 안 함 | 1: 표시함)", CVAR_FLAGS);
	ChargerSlappedTime = CreateConVar("l4d2_si_charger_disabletime","3.0", "차저에게 후려치기를 당한 생존자는 얼마 동안 제약을 받는가?", CVAR_FLAGS);

	SpitterSlap_enabled = CreateConVar("l4d2_si_spitter_enabled","1", "스피터의 후려치기 플러그인의 사용 여부는? (0: 사용 안 함 | 1: 사용함)", CVAR_FLAGS);
	SpitterSlapPower = CreateConVar("l4d2_si_spitter_power","150.0", "스피터의 후려치기를 당한 생존자는 얼마나 높이 날아가는가?", CVAR_FLAGS);
	SpitterSlapCooldown = CreateConVar("l4d2_si_spitter_cooldown","10.0", "스피터의 후려치기의 지연 시간은?", CVAR_FLAGS);
	SpitterSlapAnnounce = CreateConVar("l4d2_si_spitter_announce","1", "스피터 메시지의 표시 여부는? (0: 표시 안 함 | 1: 표시함)", CVAR_FLAGS);
	SpitterSlappedTime = CreateConVar("l4d2_si_spitter_disabletime","3.0", "스피터에게 후려치기를 당한 생존자는 얼마 동안 제약을 받는가?", CVAR_FLAGS);

	TankSlap_enabled = CreateConVar("l4d2_si_tank_enabled","1", "탱크의 후려치기 플러그인의 사용 여부는? (0: 사용 안 함 | 1: 사용함)", CVAR_FLAGS);
	TankSlapPower = CreateConVar("l4d2_si_tank_power","150.0", "탱크의 후려치기를 당한 생존자는 얼마나 높이 날아가는가?", CVAR_FLAGS);
	TankSlapCooldown = CreateConVar("l4d2_si_tank_cooldown","10.0", "탱크의 후려치기의 지연 시간은?", CVAR_FLAGS);
	TankSlapAnnounce = CreateConVar("l4d2_si_tank_announce","1", "탱크 메시지의 표시 여부는? (0: 표시 안 함 | 1: 표시함)", CVAR_FLAGS);
	TankSlappedTime = CreateConVar("l4d2_si_tank_disabletime","3.0", "탱크에게 후려치기를 당한 생존자는 얼마 동안 제약을 받는가?", CVAR_FLAGS);
	
	HookEvent("player_hurt",PlayerHurt);
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);	
	
	AutoExecConfig(true, "L4D2_Special.Infected_Slap");
}

public Action:PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new slapper = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (target == 0 || !IsClientInGame(target) || GetClientTeam(target) != 2) return Plugin_Continue;
	
	decl String:weapon[256];
	GetEventString(event, "weapon", weapon, 256);

	new boomertime = GetConVarInt(BoomerSlappedTime);
	new smokertime = GetConVarInt(SmokerSlappedTime);
	new jockeytime = GetConVarInt(JockeySlappedTime);
	new huntertime = GetConVarInt(HunterSlappedTime);
	new chargertime = GetConVarInt(ChargerSlappedTime);
	new spittertime = GetConVarInt(SpitterSlappedTime);
	new tanktime = GetConVarInt(TankSlappedTime);	
	
	if ( StrEqual(weapon, "boomer_claw") && GetClientTeam(target) == 2 && GetConVarInt(BoomerSlap_enabled) && canslap[slapper] && !GetEntProp(target, Prop_Send, "m_isIncapacitated"))	
	{
		if (!IsFakeClient(target))
		{
			gotslapped[target] = true;
			CreateTimer(GetConVarFloat(BoomerSlappedTime), ResetSlapped, target);
			PrintCenterText(target, "%N 님이 냅다 후려쳤습니다!", slapper);
			
			if (GetConVarInt(BoomerSlapAnnounce)) //PrintToChatAll("\x03[Boomer Slap] \x04%N \x01님이 \x05냅다 \x03후려친 \x04%N \x01님은 \x03%i초 \x01동안 \x04대부분\x01의 \x05행동\x01에 \x03제약\x01이 생겼습니다.", slapper, target, boomertime);
			
			for (new i=1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i))
					EmitSoundToClient(i, "player/survivor/hit/int/Punch_Boxing_FaceHit1.wav", target, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
			}		
		}
		
		PrintCenterText(slapper, "귀하는 헤픈 %N 님을, 냅다 후려치셨습니다.", target);
		EmitSoundToClient(slapper, "player/survivor/hit/int/Punch_Boxing_FaceHit1.wav");
		
		decl Float:HeadingVector[3], Float:AimVector[3];
		new Float:boomerpower = GetConVarFloat(BoomerSlapPower);
		
		GetClientEyeAngles(slapper, HeadingVector);
		
		AimVector[0] = FloatMul( Cosine( DegToRad(HeadingVector[1])  ) , boomerpower);
		AimVector[1] = FloatMul( Sine( DegToRad(HeadingVector[1])  ) , boomerpower);
		
		decl Float:current[3];
		GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);
		
		decl Float:resulting[3];
		resulting[0] = FloatAdd(current[0], AimVector[0]);	
		resulting[1] = FloatAdd(current[1], AimVector[1]);
		resulting[2] = boomerpower*2;
		
		TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
		
		if (GetConVarFloat(BoomerSlapCooldown)>0)
		{
			canslap[slapper] = false;
			CreateTimer(GetConVarFloat(BoomerSlapCooldown), ResetSlap, slapper);
		}
	}

	if ( StrEqual(weapon, "smoker_claw") && GetClientTeam(target) == 2 && GetConVarInt(SmokerSlap_enabled) && canslap[slapper] && !GetEntProp(target, Prop_Send, "m_isIncapacitated"))	
	{
		if (!IsFakeClient(target))
		{
			gotslapped[target] = true;
			CreateTimer(GetConVarFloat(SmokerSlappedTime), ResetSlapped, target);
			PrintCenterText(target, "%N 님이 냅다, 후려쳤습니다!", slapper);
			
			if (GetConVarInt(SmokerSlapAnnounce)) //PrintToChatAll("\x03[Smoker Slap] \x04%N \x01님이 \x05냅다 \x03후려친 \x04%N \x01님은 \x03%i초 \x01동안 \x04대부분\x01의 \x05행동\x01에 \x03제약\x01이 생겼습니다.", slapper, target, smokertime);
			
			for (new i=1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i))
					EmitSoundToClient(i, "player/survivor/hit/int/Punch_Boxing_FaceHit1.wav", target, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
			}
		}
		
		PrintCenterText(slapper, "귀하는 헤픈 %N 님을, 냅다 후려치셨습니다.", target);
		EmitSoundToClient(slapper, "player/survivor/hit/int/Punch_Boxing_FaceHit1.wav");
		
		decl Float:HeadingVector[3], Float:AimVector[3];
		new Float:smokerpower = GetConVarFloat(SmokerSlapPower);
		
		GetClientEyeAngles(slapper, HeadingVector);
		
		AimVector[0] = FloatMul( Cosine( DegToRad(HeadingVector[1])  ) , smokerpower);
		AimVector[1] = FloatMul( Sine( DegToRad(HeadingVector[1])  ) , smokerpower);
		
		decl Float:current[3];
		GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);
		
		decl Float:resulting[3];
		resulting[0] = FloatAdd(current[0], AimVector[0]);	
		resulting[1] = FloatAdd(current[1], AimVector[1]);
		resulting[2] = smokerpower*2;
		
		TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
		
		if (GetConVarFloat(SmokerSlapCooldown)>0)
		{
			canslap[slapper] = false;
			CreateTimer(GetConVarFloat(SmokerSlapCooldown), ResetSlap, slapper);
		}
	}
	
	if ( StrEqual(weapon, "jockey_claw") && GetClientTeam(target) == 2 && GetConVarInt(JockeySlap_enabled) && canslap[slapper] && !GetEntProp(target, Prop_Send, "m_isIncapacitated"))	
	{
		if (!IsFakeClient(target))
		{
			gotslapped[target] = true;
			CreateTimer(GetConVarFloat(JockeySlappedTime), ResetSlapped, target);
			PrintCenterText(target, "%N 님이 냅다, 후려쳤습니다!", slapper);
			
			if (GetConVarInt(JockeySlapAnnounce)) //PrintToChatAll("\x03[Jockey Slap] \x04%N \x01님이 \x05냅다 \x03후려친 \x04%N \x01님은 \x03%i초 \x01동안 \x04대부분\x01의 \x05행동\x01에 \x03제약\x01이 생겼습니다.", slapper, target, jockeytime);
			
			for (new i=1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i))
					EmitSoundToClient(i, "player/survivor/hit/int/Punch_Boxing_FaceHit1.wav", target, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
			}
		}
		
		PrintCenterText(slapper, "귀하는 헤픈 %N 님을, 냅다 후려치셨습니다.", target);
		EmitSoundToClient(slapper, "player/survivor/hit/int/Punch_Boxing_FaceHit1.wav");
		
		decl Float:HeadingVector[3], Float:AimVector[3];
		new Float:jockeypower = GetConVarFloat(JockeySlapPower);
		
		GetClientEyeAngles(slapper, HeadingVector);
		
		AimVector[0] = FloatMul( Cosine( DegToRad(HeadingVector[1])  ) , jockeypower);
		AimVector[1] = FloatMul( Sine( DegToRad(HeadingVector[1])  ) , jockeypower);
		
		decl Float:current[3];
		GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);
		
		decl Float:resulting[3];
		resulting[0] = FloatAdd(current[0], AimVector[0]);	
		resulting[1] = FloatAdd(current[1], AimVector[1]);
		resulting[2] = jockeypower*2;
		
		TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
		
		if (GetConVarFloat(JockeySlapCooldown)>0)
		{
			canslap[slapper] = false;
			CreateTimer(GetConVarFloat(JockeySlapCooldown), ResetSlap, slapper);
		}
	}
	
	if ( StrEqual(weapon, "hunter_claw") && GetClientTeam(target) == 2 && GetConVarInt(HunterSlap_enabled) && canslap[slapper] && !GetEntProp(target, Prop_Send, "m_isIncapacitated"))
	{
		if (!IsFakeClient(target))
		{
			gotslapped[target] = true;
			CreateTimer(GetConVarFloat(HunterSlappedTime), ResetSlapped, target);
			PrintCenterText(target, "%N 님이 냅다, 후려쳤습니다!", slapper);
			
			if (GetConVarInt(HunterSlapAnnounce)) //PrintToChatAll("\x03[Hunter Slap] \x04%N \x01님이 \x05냅다 \x03후려친 \x04%N \x01님은 \x03%i초 \x01동안 \x04대부분\x01의 \x05행동\x01에 \x03제약\x01이 생겼습니다.", slapper, target, huntertime);
			
			for (new i=1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i))
					EmitSoundToClient(i, "player/survivor/hit/int/Punch_Boxing_FaceHit1.wav", target, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
			}
		}
		
		PrintCenterText(slapper, "귀하는 헤픈 %N 님을, 냅다 후려치셨습니다.", target);
		EmitSoundToClient(slapper, "player/survivor/hit/int/Punch_Boxing_FaceHit1.wav");
		
		decl Float:HeadingVector[3], Float:AimVector[3];
		new Float:hunterpower = GetConVarFloat(HunterSlapPower);
		
		GetClientEyeAngles(slapper, HeadingVector);
		
		AimVector[0] = FloatMul( Cosine( DegToRad(HeadingVector[1])  ) , hunterpower);
		AimVector[1] = FloatMul( Sine( DegToRad(HeadingVector[1])  ) , hunterpower);
		
		decl Float:current[3];
		GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);
		
		decl Float:resulting[3];
		resulting[0] = FloatAdd(current[0], AimVector[0]);	
		resulting[1] = FloatAdd(current[1], AimVector[1]);
		resulting[2] = hunterpower*2;
		
		TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
		
		if (GetConVarFloat(HunterSlapCooldown)>0)
		{
			canslap[slapper] = false;
			CreateTimer(GetConVarFloat(HunterSlapCooldown), ResetSlap, slapper);
		}
	}
	
	if ( StrEqual(weapon, "charger_claw") && GetClientTeam(target) == 2 && GetConVarInt(ChargerSlap_enabled) && canslap[slapper] && !GetEntProp(target, Prop_Send, "m_isIncapacitated"))
	{
		if (!IsFakeClient(target))
		{
			gotslapped[target] = true;
			CreateTimer(GetConVarFloat(ChargerSlappedTime), ResetSlapped, target);
			PrintCenterText(target, "%N 님이 냅다, 후려쳤습니다!", slapper);
			
			if (GetConVarInt(ChargerSlapAnnounce)) //PrintToChatAll("\x03[Charger Slap] \x04%N \x01님이 \x05냅다 \x03후려친 \x04%N \x01님은 \x03%i초 \x01동안 \x04대부분\x01의 \x05행동\x01에 \x03제약\x01이 생겼습니다.", slapper, target, chargertime);
			
			for (new i=1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i))
					EmitSoundToClient(i, "player/survivor/hit/int/Punch_Boxing_FaceHit1.wav", target, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
			}
		}
		
		PrintCenterText(slapper, "귀하는 헤픈 %N 님을, 냅다 후려치셨습니다.", target);
		EmitSoundToClient(slapper, "player/survivor/hit/int/Punch_Boxing_FaceHit1.wav");
		
		decl Float:HeadingVector[3], Float:AimVector[3];
		new Float:chargerpower = GetConVarFloat(ChargerSlapPower);
		
		GetClientEyeAngles(slapper, HeadingVector);
		
		AimVector[0] = FloatMul( Cosine( DegToRad(HeadingVector[1])  ) , chargerpower);
		AimVector[1] = FloatMul( Sine( DegToRad(HeadingVector[1])  ) , chargerpower);
		
		decl Float:current[3];
		GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);
		
		decl Float:resulting[3];
		resulting[0] = FloatAdd(current[0], AimVector[0]);	
		resulting[1] = FloatAdd(current[1], AimVector[1]);
		resulting[2] = chargerpower*2;
		
		TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
		
		if (GetConVarFloat(ChargerSlapCooldown)>0)
		{
			canslap[slapper] = false;
			CreateTimer(GetConVarFloat(ChargerSlapCooldown), ResetSlap, slapper);
		}
	}

	if ( StrEqual(weapon, "spitter_claw") && GetClientTeam(target) == 2 && GetConVarInt(SpitterSlap_enabled) && canslap[slapper] && !GetEntProp(target, Prop_Send, "m_isIncapacitated"))
	{
		if (!IsFakeClient(target))
		{
			gotslapped[target] = true;
			CreateTimer(GetConVarFloat(SpitterSlappedTime), ResetSlapped, target);
			PrintCenterText(target, "%N 님이 냅다, 후려쳤습니다!", slapper);
			
			if (GetConVarInt(SpitterSlapAnnounce)) //PrintToChatAll("\x03[Spitter Slap] \x04%N \x01님이 \x05냅다 \x03후려친 \x04%N \x01님은 \x03%i초 \x01동안 \x04대부분\x01의 \x05행동\x01에 \x03제약\x01이 생겼습니다.", slapper, target, spittertime);
			
			for (new i=1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i))
					EmitSoundToClient(i, "player/survivor/hit/int/Punch_Boxing_FaceHit1.wav", target, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
			}
		}
		
		PrintCenterText(slapper, "귀하는 헤픈 %N 님을, 냅다 후려치셨습니다.", target);
		EmitSoundToClient(slapper, "player/survivor/hit/int/Punch_Boxing_FaceHit1.wav");
		
		decl Float:HeadingVector[3], Float:AimVector[3];
		new Float:spitterpower = GetConVarFloat(SpitterSlapPower);
		
		GetClientEyeAngles(slapper, HeadingVector);
		
		AimVector[0] = FloatMul( Cosine( DegToRad(HeadingVector[1])  ) , spitterpower);
		AimVector[1] = FloatMul( Sine( DegToRad(HeadingVector[1])  ) , spitterpower);
		
		decl Float:current[3];
		GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);
		
		decl Float:resulting[3];
		resulting[0] = FloatAdd(current[0], AimVector[0]);	
		resulting[1] = FloatAdd(current[1], AimVector[1]);
		resulting[2] = spitterpower*2;
		
		TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
		
		if (GetConVarFloat(SpitterSlapCooldown)>0)
		{
			canslap[slapper] = false;
			CreateTimer(GetConVarFloat(SpitterSlapCooldown), ResetSlap, slapper);
		}
	}

	if ( StrEqual(weapon, "tank_claw") && GetClientTeam(target) == 2 && GetConVarInt(TankSlap_enabled) && canslap[slapper] && !GetEntProp(target, Prop_Send, "m_isIncapacitated"))	
	{
		if (!IsFakeClient(target))
		{
			gotslapped[target] = true;
			CreateTimer(GetConVarFloat(TankSlappedTime), ResetSlapped, target);
			PrintCenterText(target, "%N 님이 냅다, 후려쳤습니다!", slapper);
			
			if (GetConVarInt(TankSlapAnnounce)) //PrintToChatAll("\x03[Tank Slap] \x04%N \x01님이 \x05냅다 \x03후려친 \x04%N \x01님은 \x03%i초 \x01동안 \x04대부분\x01의 \x05행동\x01에 \x03제약\x01이 생겼습니다.", slapper, target, tanktime);
			
			for (new i=1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i))
					EmitSoundToClient(i, "player/survivor/hit/int/Punch_Boxing_FaceHit1.wav", target, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
			}
		}
		
		PrintCenterText(slapper, "귀하는 헤픈 %N 님을, 냅다 후려치셨습니다.", target);
		EmitSoundToClient(slapper, "player/survivor/hit/int/Punch_Boxing_FaceHit1.wav");
		
		decl Float:HeadingVector[3], Float:AimVector[3];
		new Float:tankpower = GetConVarFloat(TankSlapPower);
		
		GetClientEyeAngles(slapper, HeadingVector);
		
		AimVector[0] = FloatMul( Cosine( DegToRad(HeadingVector[1])  ) , tankpower);
		AimVector[1] = FloatMul( Sine( DegToRad(HeadingVector[1])  ) , tankpower);
		
		decl Float:current[3];
		GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);
		
		decl Float:resulting[3];
		resulting[0] = FloatAdd(current[0], AimVector[0]);	
		resulting[1] = FloatAdd(current[1], AimVector[1]);
		resulting[2] = tankpower*2;
		
		TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
		
		if (GetConVarFloat(TankSlapCooldown)>0)
		{
			canslap[slapper] = false;
			CreateTimer(GetConVarFloat(TankSlapCooldown), ResetSlap, slapper);
		}
	}	
	return Plugin_Continue;	
}

public Action:ResetSlap(Handle:timer, Handle:slapper)
{
	canslap[slapper] = true;	
}

public Action:ResetSlapped(Handle:timer, Handle:target)
{
	gotslapped[target] = false;	
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client) return Plugin_Continue;
	if (!IsClientInGame(client)) return Plugin_Continue;
	
	if (GetClientTeam(client)==3)
	{
		decl String:class[100];
		GetClientModel(client, class, sizeof(class));
		
		if (StrContains(class, "boomer", false) != -1)
		{
			canslap[client]=true;
		}
		if (StrContains(class, "smoker", false) != -1)
		{
			canslap[client]=true;
		}
		if (StrContains(class, "jockey", false) != -1)
		{
			canslap[client]=true;
		}
		if (StrContains(class, "hunter", false) != -1)
		{
			canslap[client]=true;
		}
		if (StrContains(class, "charger", false) != -1)
		{
			canslap[client]=true;
		}
		if (StrContains(class, "spitter", false) != -1)
		{
			canslap[client]=true;
		}
		if (StrContains(class, "tank", false) != -1)
		{
			canslap[client]=true;
		}		
	}
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	gotslapped[target] = false;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	new boomertime = GetConVarInt(BoomerSlappedTime);
	new smokertime = GetConVarInt(SmokerSlappedTime);
	new jockeytime = GetConVarInt(JockeySlappedTime);
	new huntertime = GetConVarInt(HunterSlappedTime);
	new chargertime = GetConVarInt(ChargerSlappedTime);
	new spittertime = GetConVarInt(SpitterSlappedTime);
	new tanktime = GetConVarInt(TankSlappedTime);

	decl String:mName[64];

	if (gotslapped[client])
	{
		if (buttons & (IN_ATTACK|IN_ATTACK2|IN_RELOAD|IN_USE|IN_JUMP))
		{
			buttons &= ~(IN_ATTACK|IN_ATTACK2|IN_RELOAD|IN_USE|IN_JUMP);
			if (StrContains(mName, "boomer") != -1)
			{
				PrintCenterText(client, "부머에게 후려 맞아서 %i초 동안, 대부분의 행동에 제약이 생겼습니다!", boomertime);
				FakeClientCommandEx(client, "vocalize ReviveMeINterrupted");
			}
			if (StrContains(mName, "smoker") != -1)
			{
				PrintCenterText(client, "스모커에게 후려 맞아서 %i초 동안, 대부분의 행동에 제약이 생겼습니다!", smokertime);
				FakeClientCommandEx(client, "vocalize ReviveMeINterrupted");
			}
			if (StrContains(mName, "jockey") != -1)
			{
				PrintCenterText(client, "자키에게 후려 맞아서 %i초 동안, 대부분의 행동에 제약이 생겼습니다!", jockeytime);
				FakeClientCommandEx(client, "vocalize ReviveMeINterrupted");
			}
			if (StrContains(mName, "hunter") != -1)
			{
				PrintCenterText(client, "헌터에게 후려 맞아서 %i초 동안, 대부분의 행동에 제약이 생겼습니다!", huntertime);
				FakeClientCommandEx(client, "vocalize ReviveMeINterrupted");
			}
			if (StrContains(mName, "charger") != -1)
			{
				PrintCenterText(client, "차저에게 후려 맞아서 %i초 동안, 대부분의 행동에 제약이 생겼습니다!", chargertime);
				FakeClientCommandEx(client, "vocalize ReviveMeINterrupted");
			}
			if (StrContains(mName, "spitter") != -1)
			{
				PrintCenterText(client, "스피터에게 후려 맞아서 %i초 동안, 대부분의 행동에 제약이 생겼습니다!", spittertime);
				FakeClientCommandEx(client, "vocalize ReviveMeINterrupted");
			}
			if (StrContains(mName, "hulk") != -1)
			{
				PrintCenterText(client, "탱크에게 후려 맞아서 %i초 동안, 대부분의 행동에 제약이 생겼습니다!", tanktime);
				FakeClientCommandEx(client, "vocalize ReviveMeINterrupted");
			}
		}
	}
	return Plugin_Continue;
}
