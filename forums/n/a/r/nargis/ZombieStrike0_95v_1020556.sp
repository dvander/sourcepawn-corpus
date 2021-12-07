
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define VIRTUAL_RESPAWN 23
#define VIRTUAL_CHANGE_TEAM 81

new UserMsg:ShakeID;
new StartTimerCount;
new bool:GameStart;
new bool:SoundOn;
new bool:MotherOn;
new GameCount;
new bool:ZombiePlayer[33];
new bool:ZTelebool[33];
new Float:SaveOrigin[33][3];
new Float:SaveZtele[33][3];
new Float:SaveAngle[33][3];
new g_offsCollisionGroup;
new Handle:ChangeTeamHandle = INVALID_HANDLE;
new Handle:RespawnHandle = INVALID_HANDLE;
new bool:MapStartBool = false;
new String:GDescript[64] = "Zombie Strike 0.95v";



/*
	필요요소 설정
				*/

public Plugin:myinfo = 
{
	name = "Zombie Strike",
	author = "Nargis",
	description = "Zombie mod for hl2mp",
	version = "0.9.5.0",
	url = "http://cafe.naver.com/hl2mp2"
	
};
public bool:IsStillAlive(Client)
{
	if(IsValidEntity(Client))
	{
		if(Client <= GetMaxClients())
		{
			if(Client != 0)
			{
				if(IsClientConnected(Client))
				{
					if(IsPlayerAlive(Client))
					{
						if(!IsClientObserver(Client))
						{
							if(!IsFakeClient(Client))
							{
								return true;
							}
						}
					}
				}
			}
		}
	}	return false;
}



public Action:OnGetGameDescription(String:GDesc[64])
{

	strcopy(GDesc, 64, GDescript);

	if(MapStartBool)
	{
		return Plugin_Changed;
	}
	return Plugin_Handled;
}

public OnMapEnd()
{
	MapStartBool = false;
}

public SoundingToWorld(String:SoundWav[])
{
	EmitSoundToAll(SoundWav,SOUND_FROM_PLAYER,SNDCHAN_USER_BASE,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,NULL_VECTOR,NULL_VECTOR,true,0.0);
}

public Sounding(Client, String:SoundWav[])
{
	new Float:CPos[3];
	GetEntPropVector(Client, Prop_Send, "m_vecOrigin", CPos);	
	EmitSoundToAll(SoundWav,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,CPos,NULL_VECTOR,true,0.0);
}

public bool:IsStillConnect(Client)
{
	if(IsValidEntity(Client))
	{
		if(Client <= GetMaxClients())
		{
			if(Client != 0)
			{
				if(IsClientConnected(Client))
				{
					return true;
				}
			}
		}
	}	return false;
}

/*
	플러그인 기본 요소 설정
				*/

public OnPluginStart()
{
	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	RegConsoleCmd("say", SayHook);
	ShakeID = GetUserMessageId("Shake");
	CreateTimer(1.0, STimer);
	StartTimerCount = 20;
	GameStart = false;
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(VIRTUAL_CHANGE_TEAM);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
	ChangeTeamHandle = EndPrepSDKCall();
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(VIRTUAL_RESPAWN);
	RespawnHandle = EndPrepSDKCall();
}

public OnPreThink(Client)
{
	new Team_Index;
	Team_Index = GetClientTeam(Client);

	decl String:WeaponName[32];
	GetClientWeapon(Client, WeaponName, 32);

	if(Team_Index == 3)
	{
		if(StrEqual(WeaponName, "weapon_physcannon", false))
		{
			new iButtons = GetClientButtons(Client);

			if(iButtons & IN_ATTACK)
			{
				iButtons &= ~IN_ATTACK;
				SetEntProp(Client, Prop_Data, "m_nButtons", iButtons);
			}
		}

		if(StrEqual(WeaponName, "weapon_ar2", false))
		{
			new iButtons = GetClientButtons(Client);

			if(iButtons & IN_ATTACK2)
			{
				iButtons &= ~IN_ATTACK2;
				SetEntProp(Client, Prop_Data, "m_nButtons", iButtons);
			}
		}
	}


}

public Action:SayHook(Client, Args)
{
	new String:Cmd[256];
	GetCmdArgString(Cmd, sizeof(Cmd));
	StripQuotes(Cmd);
	TrimString(Cmd);

	if(StrContains(Cmd, "!e", false) == 0)
	{
		SetCamera(Client, false);
	}

	if(StrContains(Cmd, "!r", false) == 0)
	{
		SoundingToWorld("test/temp/soundscape_test/tv_music.wav");
	}

	if(StrContains(Cmd, "!ztele", false) == 0)
	{
		if(!ZTelebool[Client])
		{
			if(GetClientTeam(Client) == 2)
			{
				TeleportEntity(Client, SaveZtele[Client],NULL_VECTOR,NULL_VECTOR);
				ZTelebool[Client] = true;
			}
		}
	}
}

SetCamera(Client, Sight) 
{
	if (Sight) {
		SetEntPropEnt(Client, Prop_Send, "m_hObserverTarget", 0);
		SetEntProp(Client,    Prop_Send, "m_iObserverMode",   1);
		SetEntProp(Client,    Prop_Send, "m_bDrawViewmodel",  0);
		SetEntProp(Client,    Prop_Send, "m_iFOV",            120);
	} else {
		SetEntPropEnt(Client, Prop_Send, "m_hObserverTarget", -1);
		SetEntProp(Client,    Prop_Send, "m_iObserverMode",   0);
		SetEntProp(Client,    Prop_Send, "m_bDrawViewmodel",  1);
		SetEntProp(Client,    Prop_Send, "m_iFOV",            90);
	}
}

public OnClientPutInServer(Client)
{
	SDKHook(Client, SDKHook_OnTakeDamage, OnTakeDamages);
	SDKHook(Client, SDKHook_Spawn, PlayerSpawn);
	SDKHook(Client, SDKHook_WeaponSwitch, OnWeaponSwitch);
	SDKHook(Client, SDKHook_PreThink, OnPreThink);
}

public PlayerSpawn(Client)
{
	if(IsStillConnect(Client))
	{
		if(GameStart)
		{
			if(!ZombiePlayer[Client])
			{
				SDKCall(ChangeTeamHandle, Client, 1);
				ClientCommand(Client, "r_screenoverlay 0");
			}
		} else {
			ClientCommand(Client, "r_screenoverlay 0");
			SDKCall(ChangeTeamHandle, Client, 3);
		}
	}
}

public OnMapStart()
{
	/*CreateTimer(0.1, Downs);*/
	PrecacheModel("models/player/zombine/t_phoenix.mdl", true);
	PrecacheModel("models/zombie/classic.mdl", true);
	PrecacheSound("items/smallmedkit1.wav", true);
	PrecacheSound("test/temp/soundscape_test/tv_music.wav", true);
	PrecacheSound("zsound.wav", true);
	PrecacheSound("npc/zombie/zombie_voice_idle11.wav", true);
	PrecacheSound("ambient/atmosphere/hole_amb3.wav", true);
	StartTimerCount = 30;
	SoundOn = false;
	MotherOn = false;
	MapStartBool = true;
	for(new x = 0;x < 33;x++)
	{
		ZombiePlayer[x] = false;
		ZTelebool[x] = false;
	}
	GameStart = false;
}

/*
	플러그인 이벤트 설정

				*/


public Action:OnTakeDamages(Client, &Attacker, &Weapon, &Float:Damage, &DamageType)
{
	if(IsStillAlive(Client) && IsStillAlive(Attacker) && GetClientTeam(Client) == 3 && GetClientTeam(Attacker) == 2)
	{
		SetEntProp(Client, Prop_Data, "m_lifeState", 2);
		new Handle:DeathEvents = CreateEvent("player_death");
 		if(!IsStillAlive(Attacker))
		{
			SetEventInt(DeathEvents, "attacker", GetClientUserId(Client));
		} else {
			SetEventInt(DeathEvents, "attacker", GetClientUserId(Attacker));
		}
		SetEventInt(DeathEvents, "userid", GetClientUserId(Client));
		SetEventString(DeathEvents, "weapon", "weapon_crowbar");
		SetEventBool(DeathEvents, "headshot", false);
		FireEvent(DeathEvents);
		SetEntProp(Client, Prop_Data, "m_lifeState", 0);
		SetEntProp(Attacker, Prop_Data, "m_iFrags", GetClientFrags(Client) + 2);
		SetEntProp(Client, Prop_Data, "m_iDeaths", GetClientDeaths(Client) + 1);
		MakeZombie(Client);
		Damage = 0.0;
		return Plugin_Changed;
	}

	if(IsStillAlive(Client) && IsStillAlive(Attacker))
	{
		new Float:Cangle[3], Float:KnuckBacks[3];
		GetClientEyeAngles(Attacker, Cangle);

		KnuckBacks[0] = FloatMul( Cosine( DegToRad(Cangle[1])  ) , -Damage * 12);
		KnuckBacks[1] = FloatMul( Sine( DegToRad(Cangle[1])  ) , -Damage * 12);
		KnuckBacks[2] = FloatMul( Sine( DegToRad(Cangle[0])  ) , Damage * 12);
		Shake(Client, 0.5, 2.0);
		TeleportEntity(Client, NULL_VECTOR, NULL_VECTOR, KnuckBacks );
	}

	return Plugin_Continue;
}

public Action:OnWeaponSwitch(Client, Ent)
{
	if(IsStillAlive(Client) && GetClientTeam(Client) == 2)
	{	
		new String:Target[64];
		GetEdictClassname(Ent, Target, sizeof(Target));

		if(StrEqual(Target, "weapon_crowbar") == false)
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
		
}

public Action:WeaponRemoving(Handle:Timer, any:Client)
{
	if(IsStillAlive(Client))
	{
		new Weapon_Offset = FindSendPropOffs("CHL2MP_Player", "m_hMyWeapons");
		new Max_Guns = 48;

		for(new i = 0; i < Max_Guns; i = (i + 4))
		{
			new Weapon_ID = GetEntDataEnt2(Client, Weapon_Offset + i);

			if(Weapon_ID > 0)
			{
				RemovePlayerItem(Client, Weapon_ID);
				RemoveEdict(Weapon_ID);
			}
		}
		GivePlayerItem(Client, "weapon_crowbar");
	}
}

public Shake(Client, Float:Length, Float:Severity)
{
	new Send_Client[2];
	Send_Client[0] = Client;
	new Handle:View_Message;
	View_Message = StartMessageEx(ShakeID, Send_Client, 1);
	BfWriteByte(View_Message, 0);
	BfWriteFloat(View_Message, Severity);
	BfWriteFloat(View_Message, 10.0);
	BfWriteFloat(View_Message, Length);
	EndMessage();
}

public MakeZombie(Client)
{
	Sounding(Client,"npc/zombie/zombie_voice_idle11.wav");
	GetClientAbsAngles(Client, SaveAngle[Client]); 
	GetClientAbsOrigin(Client, SaveOrigin[Client]);
	GetClientAbsOrigin(Client, SaveZtele[Client]);
	if(IsStillConnect(Client))
	{
		SDKCall(ChangeTeamHandle, Client, 2);
	}
	ZombiePlayer[Client] = true;
	CreateTimer(0.03, RespawnClient, Client);
}

public Action:STimer(Handle:Timer)
{
	if(!GameStart)
	{
		if(StartTimerCount > 0)
		{
			if(!SoundOn)
			{
				SoundingToWorld("ambient/atmosphere/hole_amb3.wav");
				SoundOn = true;
			}
			StartTimerCount--;
			SetHudTextParams(-1.0, -1.0, 0.8, 255, 255, 255, 255, 0, 0.5, 0.1, 0.2);

			for(new i = 0; i <= GetMaxClients(); i++)
			{
				if(IsStillAlive(i))
				{
					ShowHudText(i, -1, "%d", StartTimerCount);
				}
			}
			CreateTimer(1.0, STimer);
		} else {
			new AlivePlayer = 0;
			new AliveZombie = 0;
			for(new x; x <= GetMaxClients(); x++)
			{
				if(IsStillAlive(x) && GetClientTeam(x) == 3)
				{
					AlivePlayer++;
				} else if(IsStillAlive(x) && GetClientTeam(x) == 2)
				{
					AliveZombie++;
				}
			}

			if(AlivePlayer + AliveZombie > 1)
			{
				new X, Selected[33], Victim;

				for(new i = 0; i <= GetMaxClients(); i++)
				{
					if(IsStillAlive(i))
					{
						X++;
						Selected[X] = i;
					}

					if(i == GetMaxClients())
					{
						new Clients = GetRandomInt(1, X);
						Victim = Selected[Clients];
					}
				}
				MakeZombie(Victim);
				GameStart = true;
				StartTimerCount = 10;
				GameCount = 150;
				SoundOn = false;
				CreateTimer(1.0, STimer);
			} else {
				CreateTimer(1.0, ResetGame);
			}
		}
	} else {
		new AlivePlayer = 0;
		new AliveZombie = 0;
		GameCount--;
		for(new x; x <= GetMaxClients(); x++)
		{
			SetHudTextParams(-1.0, 0.05, 0.8, 255, 255, 255, 255, 0, 3.0, 0.1, 0.2);
			if(IsStillAlive(x) && GetClientTeam(x) == 3)
			{
				AlivePlayer++;
			} else if(IsStillAlive(x) && GetClientTeam(x) == 2)
			{
				AliveZombie++;
			}

			if(IsStillConnect(x))
			{
				ShowHudText(x, -1, "Left Time : %d secs", GameCount);
			}

			if(IsStillConnect(x) && IsClientObserver(x))
			{
				SetHudTextParams(-1.0, -0.8, 1.0, 80, 255, 120, 255, 0, 3.0, 0.1, 0.2);
				ShowHudText(x, -1, "Please wait for next round");
			}
		}

		if(GameCount <= 0)
		{
			CreateTimer(1.0, ResetGame);
			return Plugin_Continue;
		}

		if(AlivePlayer == 0)
		{
			SetHudTextParams(-1.0, -1.0, 2.0, 255, 255, 255, 255, 0, 3.0, 0.1, 0.2);
			for(new x; x <= GetMaxClients(); x++)
			{
				if(IsStillConnect(x))
				{
					if(GetClientTeam(x) == 2)
					{
						SetEntProp(x, Prop_Data, "m_iFrags", GetClientFrags(x) + 5);
					}
					SoundingToWorld("npc/zombie/zombie_voice_idle11.wav");
					ShowHudText(x, -1, "Zombie Win");
				}
			}
			CreateTimer(1.0, ResetGame);
		} else if(AliveZombie == 0) {
			SetHudTextParams(-1.0, -1.0, 2.0, 255, 255, 255, 255, 0, 3.0, 0.1, 0.2);
			for(new x; x <= GetMaxClients(); x++)
			{
				if(IsStillConnect(x))
				{
					if(GetClientTeam(x) == 3)
					{
						SetEntProp(x, Prop_Data, "m_iFrags", GetClientFrags(x) + 5);
					}
					SoundingToWorld("test/temp/soundscape_test/tv_music.wav");
					ShowHudText(x, -1, "Human Win");
				}
			}
			CreateTimer(1.0, ResetGame);
		} else if(AlivePlayer + AliveZombie > 1){
			CreateTimer(1.0, STimer);
		}
	}
	return Plugin_Continue;
}

public Action:RespawnClient(Handle:Timer, any:Client)
{
	if(IsStillConnect(Client))
	{
		SDKCall(RespawnHandle, Client);
		if(GetClientTeam(Client) == 2)
		{
			new AlivePlayer = 0;	
			for(new x; x <= GetMaxClients(); x++)
			{
				if(IsStillAlive(x) && GetClientTeam(x) == 3)
				{
					AlivePlayer++;
				}
			}
			SetEntityModel(Client,"models/zombie/classic.mdl");
			//SetEntityModel(Client,"models/player/zombine/t_phoenix.mdl");
			if(MotherOn)
			{
				SetEntityHealth(Client, 50 * AlivePlayer + 50);
			} else {
				MotherOn = true
				SetEntityHealth(Client, 100 * AlivePlayer + 100);
			}
			SetEntPropFloat(Client, Prop_Data, "m_flLaggedMovementValue", 1.2);
			Shake(Client, 3.0, 6.0);
			CreateTimer(0.1, WeaponRemoving, Client);
			new Float:Jumps[3];
			Jumps[0] = FloatMul( Cosine( DegToRad(SaveAngle[Client][1])  ) , 800.0);
			Jumps[1] = FloatMul( Sine( DegToRad(SaveAngle[Client][1])  ) , 800.0);
			Jumps[2] = FloatMul( Sine( DegToRad(SaveAngle[Client][0])  ) , -800.0);
			TeleportEntity(Client, SaveOrigin[Client], SaveAngle[Client], Jumps);
			ClientCommand(Client, "r_screenoverlay debug/yuv.vmt");
			//ClientCommand(Client, "r_screenoverlay tp_refract.vmt");
			ZombiePlayer[Client] = false;
			SetEntData(Client, g_offsCollisionGroup, 2, 4, true);
			CreateTimer(4.0, Blockon,Client);
			Sounding(Client,"npc/zombie/zombie_voice_idle11.wav");
		} else {
			ClientCommand(Client, "r_screenoverlay 0");
			SetEntPropFloat(Client, Prop_Data, "m_flLaggedMovementValue", 1.0);
		}
	}
}

public Action:Blockon(Handle:Timer, any:Client)
{
	if(IsStillAlive(Client))
	{
		SetEntData(Client, g_offsCollisionGroup, 5, 4, true);
	}
}


public Action:ResetGame(Handle:Timer)
{
	new AlivePlayer = 0;
	for(new x; x <= GetMaxClients(); x++)
	{
		if(IsStillConnect(x))
		{
			AlivePlayer++;
		}
	}

	if(AlivePlayer <= 1)
	{
		PrintToChatAll("\x04Please another player wait....!");
		for(new x; x <= GetMaxClients(); x++)
		{
			if(IsStillConnect(x))
			{
				ZombiePlayer[x] = false;
				if(GetClientTeam(x) == 2)
				{
					CreateTimer(1.0, RejoinClient, x);
				}
			}
		}
		StartTimerCount = 20;
		MotherOn = false
		GameStart = false;
		CreateTimer(1.0, STimer);
	} else {
		for(new x; x <= GetMaxClients(); x++)
		{
			if(IsStillConnect(x))
			{
				ZombiePlayer[x] = false;
				ZTelebool[x] = false;
				SDKCall(ChangeTeamHandle, x, 1);
			}
		}
		ServerCommand("mp_restartgame 1");
		CreateTimer(2.5, GTimer);

	}
	
}

public Action:GTimer(Handle:Timer)
{
	StartTimerCount = 25;
	GameStart = false;
	for(new x; x <= GetMaxClients(); x++)
	{
		if(IsStillConnect(x))
		{
			ZombiePlayer[x] = false;
			new Float:RejoinGame = GetRandomFloat(0.20, 0.65) * GetRandomInt(5, 8);
			CreateTimer(RejoinGame, RejoinClient, x);

		}
	}
	CreateTimer(1.0, STimer);
}

public Action:RejoinClient(Handle:Timer, any:Client)
{
	if(IsStillConnect(Client))
	{
		SDKCall(ChangeTeamHandle, Client, 3);
		CreateTimer(0.03, RespawnClient, Client);
	}

}
