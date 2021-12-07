#include <sdktools>
#include <sdkhooks>
#include <smlib>

#define prefix "\x05[Медик]"

public Plugin:myinfo=
{
	name = "[Medic]",
	author = "BHaType(Thanks AlexMy for some fix)",
	description = "В начале раунда, 1 из игроков становится медиком и может лечить остальных игроков.",
	version = "2.0.0",
	url = "https://steamcommunity.com/id/fallinourblood/"
};

new bool:IsHealer[MAXPLAYERS+1] = false;
new bool:IsUsing = false;
new bool:hHasLeftArea = false;
new bool:IsHaveMedic = false;
static Handle hHealCount, hMaxHealth, hDurationRing, hIncapHealCount, hIncapMaxHeal, hRangeOfHeal, hRadiusOfRing, hEnabledThWalls, IsPlugin, OnlyForAdmin;

Handle HealTimer[MAXPLAYERS+1], TimerRepeatRing;

int Healer;

int g_HaloSprite;
int g_BeamSprite;
int yourColor[4] = {220, 20, 60, 255};
int yourColor2[4] = {205, 92, 92, 255};

public OnPluginStart()
{
	hHealCount = CreateConVar("hCvarHealCount", "5", "Кол-во лечения", FCVAR_NONE, true, 1.0, true, 50000.0);
	hMaxHealth = CreateConVar("hCvarMaxHeal", "80", "Максимальный прохил", FCVAR_NONE);
	
	hIncapHealCount = CreateConVar("hCvarIncapHealCount", "15", "Кол-во лечения инкапнутых", FCVAR_NONE, true, 1.0, true, 50000.0);
	hIncapMaxHeal = CreateConVar("hCvarMaxHealIncap", "200", "Максимальный прохил инкапнутых", FCVAR_NONE, true, 1.0, true, 50000.0);
	
	hDurationRing = CreateConVar("hCvarDuration", "15.0", "Время жизни кольца", FCVAR_NONE, true, 1.0, true, 25.0)
	hRangeOfHeal = CreateConVar("hCvarRangeHeal", "400.0", "Макс. дистанция лечения", FCVAR_NONE)
	hRadiusOfRing = CreateConVar("hCvarRingRadius", "400.0", "Радиус кольца", FCVAR_NONE)
	hEnabledThWalls = CreateConVar("hCvarIsVisible", "0", "Будет ли работать через стены. 1 - да , 0 нет.", FCVAR_NONE, true, 0.0, true, 1.0)
	
	IsPlugin = CreateConVar("hEnable", "1", "Включен ли плагин 1 - да 0 - нет", FCVAR_NONE, true, 0.0, true, 1.0)
	OnlyForAdmin = CreateConVar("hOnlyForAdmin", "0", "Только для администраторов команда !bm?", FCVAR_NONE, true, 0.0, true, 1.0)
	//hDistance = CreateConVar("hCvarDuration", "600.0", "Дистаннция", FCVAR_NONE)
	//CoolDown = CreateConVar("hCvarCoolDown", "15.0", "Кул даун юзания", FCVAR_NONE)
	RegConsoleCmd("sm_rmedic", hRandomMedic);
	RegConsoleCmd("sm_bm", hBecomeMedic);
	RegAdminCmd("sm_cm", hChooseMedic, ADMFLAG_ROOT);
	RegAdminCmd("sm_choosemedic", hChooseMedic, ADMFLAG_ROOT);
	HookConVarChange(IsPlugin, OnCvarChanged);
	AutoExecConfig(true, "hMedicPlug");
	LoadTranslations("medic.translations");
}

public OnMapStart()
{
	if(GetConVarInt(IsPlugin) == 1)
	{
		HookEvent("player_team", hMedicChangeTeam)
		HookEvent("bullet_impact", hImpact)
		HookEvent("player_left_start_area", hLeftStart);
		HookEvent("door_open", hLeftStart);
	}
	
	g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt", true);
	
	for(int i = 1; i <= MaxClients; ++i)
	{
		IsHealer[i] = false;
	}
	IsUsing = false;
	hHasLeftArea = false;
}

public Action:hChooseMedic(client, args)
{
	if(GetConVarInt(IsPlugin) != 1) return;
	
	DisplayChooseMedic(client)
}

DisplayChooseMedic(client)
{
	if(GetConVarInt(IsPlugin) != 1) return;
	
	Handle ChooseMedic = CreateMenu(AdmSetMedic);
	SetMenuTitle(ChooseMedic, "%t", "WhoWillBecomeMedic");
	//SetMenuTitle(ChooseMedic, "Кто станет медиком:");
	
	decl String:userid[15], String:name[32]; 
	
	for (int i = 1; i <= MaxClients; i++) 
	{ 
		if (bIsSurvivor(i) && !IsFakeClient(i)) 
		{
			IntToString(GetClientUserId(i), userid, 15); 
			GetClientName(i, name, 32); 
			AddMenuItem(ChooseMedic, userid, name);
		} 
	}
	DisplayMenu(ChooseMedic, client, MENU_TIME_FOREVER);
}

public AdmSetMedic(Handle:CallBackMedic, MenuAction:action, client, option) 
{ 
	if(GetConVarInt(IsPlugin) != 1) return;
	
	if (action == MenuAction_End) 
	{ 
		CloseHandle(CallBackMedic); 
		return; 
	} 
	if (action != MenuAction_Select) return; 
	decl String:userid[15]; 
	GetMenuItem(CallBackMedic, option, userid, 15); 
	int target = GetClientOfUserId(StringToInt(userid)); 
	if (bIsSurvivor(target) && target && IsClientInGame(target)) 
	{
		for(int i = 1; i <= MaxClients; ++i)
		{
			IsHealer[i] = false;
		}
		
		Healer = target;
		char sWeaponEx[32]
		static int slot;
		if((slot = GetPlayerWeaponSlot(Healer, 1)) && slot != -1)
		if (!IsValidEntity(slot))return;
		
		GetEntityClassname(slot, sWeaponEx, sizeof(sWeaponEx))
		
		if(StrEqual(sWeaponEx, "weapon_pistol_magnum"))
		{
			RemovePlayerItem(Healer, slot)
			GiveFunction(Healer, "pistol")
		}
		IsHealer[target] = true;
		GiveFunction(target, "pistol_magnum")
	}
}

public Action:hBecomeMedic(client, args)
{
	if(GetConVarInt(IsPlugin) != 1) return;
	
	if(!hHasLeftArea)
	{
		Client_PrintToChat(client, true, "%t", "RoundHastNotStartedYet", prefix);
		//CPrintToChat(client, "%s {blue}Раунд ещё не начался.", prefix)
	}
	
	if(GetConVarInt(OnlyForAdmin) == 1)
	{
		if(IsPlayerAdmin(client))
		{
			if(hHasLeftArea)
			{
				if(bIsSurvivor(client))
				{
					if(IsHaveMedic == false)
					{
						IsHealer[client] = true;
						IsHaveMedic = true;
						Client_PrintToChatAll(true, "%t", "ClientWriteCommand_BM", prefix, client)
						//CPrintToChatAll("%s {red}%N \x05прописал \x04!bm \x05и стал новым медиком", prefix, client);
						GiveFunction(client, "pistol_magnum");
						Healer = client;
					}
				}
			}
		}
	}
	else if(GetConVarInt(OnlyForAdmin) == 0)
	{
		if(hHasLeftArea)
		{
			if(bIsSurvivor(client))
			{
				if(IsHaveMedic == false)
				{
					IsHealer[client] = true;
					IsHaveMedic = true;
					Client_PrintToChatAll(true, "%t", "ClientWriteCommand_BM", prefix, client)
					//CPrintToChatAll("%s {red}%N \x05прописал \x04!bm \x05и стал новым медиком", prefix, client);
					GiveFunction(client, "pistol_magnum");
					Healer = client;
				}
			}
		}
	}
}

public Action:hRandomMedic(client, args)
{
	if(GetConVarInt(IsPlugin) != 1) return;
	if(IsHealer[client])
	{
		int SurvivorsCount = 0, NewHealer;
		for(int i = 1; i <= MaxClients; ++i)
		{
			if(bIsSurvivor(i))
			{
				SurvivorsCount++;
			}
		}
		if (SurvivorsCount > 1)
		{
			if(GetConVarInt(OnlyForAdmin))
				NewHealer = GetRandomClient(true, client);
			else
				NewHealer = GetRandomClient(false, client);
			if(bIsSurvivor(NewHealer))
			{
				IsHealer[client] = false;
				IsHealer[NewHealer] = true;
				IsHaveMedic = true;
				Client_PrintToChatAll(true, "%t", "ClientGivesMedicRandomPlayer", prefix, client)
				Client_PrintToChatAll(true, "%t", "ClientBecomeNewMdeic", prefix, NewHealer)
				//CPrintToChatAll("%s {red}%N \x05отдал медика рандомному игроку.", prefix, client);
				//CPrintToChatAll("%s {red}%N \x05стал новым медиком", prefix, NewHealer);
				new weap = GetPlayerWeaponSlot(client, 1);
				RemovePlayerItem(client, weap);
				GiveFunction(NewHealer, "pistol_magnum");
				GiveFunction(client, "pistol");
				Healer = NewHealer;
			}
		}
		else
		{
			Client_PrintToChatAll(true, "%t", "Need2PlayersAtLeast", prefix)
			//CPrintToChatAll("%s {red}Нужно, как минимум 2 игрока за выживших.", prefix);
		}
	}
	else
	{
		Client_PrintToChat(client, true, "%t", "YouAreNotMedic", prefix)
		//CPrintToChat(client, "%s {red}Вы не медик.", prefix);
	}
}

public hLeftStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(IsPlugin) != 1) return;
	if(hHasLeftArea == false && !IsHaveMedic)
	{
		int client;
		if(GetConVarInt(OnlyForAdmin))
			client = GetRandomClient(true);
		else
			client = GetRandomClient(false);
		if(bIsSurvivor(client))
		{
			IsHealer[client] = true;
			GiveFunction(client, "pistol_magnum")
			Client_PrintToChatAll(true, "%t", "RoundStart", prefix)
			//CPrintToChatAll("%s {blue}%N \x05стал медиком", prefix, client);
			hHasLeftArea = true;
			IsHaveMedic = true;
			Healer = client;
		}
	}
}

public hMedicChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(IsPlugin) != 1) return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	int healer, HealerId;
	
	if(bIsSurvivor(client))
	{
		new bool:IsDissconect = GetEventBool(event, "disconnect");
		int TeamOld = GetEventInt(event, "oldteam");
		int TeamNew = GetEventInt(event, "team");
		if(IsHealer[client])
		{
			int SurvivorsCount = 0;
			for(int i = 1; i <= MaxClients; ++i)
			{
				if(bIsSurvivor(i))
				{
					SurvivorsCount++;
				}
			}
			if(SurvivorsCount > 2)
			{
				if(GetConVarInt(OnlyForAdmin))
					healer = GetRandomClient(true, client);
				else
					healer = GetRandomClient(false, client);
				HealerId = GetClientOfUserId(healer)
				if(IsDissconect)
				{
					IsHealer[healer] = true;
					IsHealer[client] = false;
					Client_PrintToChatAll(true, "%t", "MedicLeftTheGame", prefix, client)
					Client_PrintToChatAll(true, "%t", "ClientBecomeNewMdeic", prefix, healer)
					//CPrintToChatAll("%s \x05Медик %N \x04 вышел.", prefix, client)
					//CPrintToChatAll("%s {red}%N \x05стал новым медиком", prefix, healer);
					GiveFunction(healer, "pistol_magnum");
					new weap = GetPlayerWeaponSlot(client, 1);
					RemovePlayerItem(client, weap);
					GiveFunction(client, "pistol");
					Healer = healer;
				}
				if(!IsDissconect)
				{
					if(TeamNew == 1 && TeamOld == 2)
					{
						Client_PrintToChatAll(true, "%t", "MedicGoesAfk", prefix, client)
						//CPrintToChatAll("%s \x05Медик %N \x04 ушёл в афк", prefix, client)
					}
					else if(TeamNew == 3 && TeamOld == 2)
					{
						Client_PrintToChatAll(true, "%t", "MedicChangeTeam", prefix, client)
						//CPrintToChatAll("%s \x05Медик %N \x04поменял команду", prefix, client)
					}
					if(HealerId > 0)
					{
						GiveFunction(healer, "pistol_magnum");
						IsHealer[healer] = true;
						IsHealer[client] = false;
						Client_PrintToChatAll(true, "%t", "ClientBecomeNewMdeic", prefix, healer)
						//CPrintToChatAll("%s {red}%N \x05стал новым медиком", prefix, healer);
						Healer = healer;
						new WeaponClient = GetPlayerWeaponSlot(client, 1);
						if (!IsValidEntity(WeaponClient)) return;
						
						char sWeaponEx[32];
						GetEntityClassname(WeaponClient, sWeaponEx, sizeof(sWeaponEx))
									
						new WeaponHealer = GetPlayerWeaponSlot(healer, 1);
						if (!IsValidEntity(WeaponHealer)) return;
						char sWeaponExHealer[32];
						GetEntityClassname(WeaponHealer, sWeaponExHealer, sizeof(sWeaponExHealer))
						if(!(StrEqual(sWeaponExHealer, "weapon_pistol_magnum")))
						{
							GiveFunction(healer, "pistol_magnum");
						}
						if(StrEqual(sWeaponEx, "weapon_pistol_magnum"))
						{
							RemovePlayerItem(client, WeaponClient);
							GiveFunction(client, "pistol");
						}
					}
				}
			}
			else
			{
				for(int i = 1; i <= MaxClients; ++i)
				{
					IsHealer[i] = false;
				}
				IsHaveMedic = false;
				Client_PrintToChatAll(true, "%t", "ToSetANewMedicNeedPlayers", prefix)
				Client_PrintToChatAll(true, "%t", "JointeamAndWtireBm", prefix)
				//CPrintToChatAll("%s {red}Для рандомного выбора медика нужно, как минимум 2 игрока!", prefix);
				//CPrintToChatAll("%s {blue}Зайдите за команду выживших и пропишите !bm, чтобы стать медиком!", prefix);
			}
		}
	}
}

public hImpact(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(IsPlugin) != 1) return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Float:f_Pos[3];
	f_Pos[0] = GetEventFloat(event, "x");
	f_Pos[1] = GetEventFloat(event, "y");
	f_Pos[2] = GetEventFloat(event, "z");
	
	f_Pos[2] += 30;
	if(IsUsing != true)
	{
		if(bIsSurvivor(client))
		{
			static int iCurrentWeapon;
			if((iCurrentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")) && (iCurrentWeapon == -1)) return;
			char sWeaponEx[32];
			GetEntityClassname(iCurrentWeapon, sWeaponEx, sizeof(sWeaponEx))
			if(StrEqual(sWeaponEx, "weapon_pistol_magnum"))
			{
				if(IsHealer[client])
				{
					TE_SetupBeamRingPoint(f_Pos, GetConVarFloat(hRadiusOfRing) - 5, GetConVarFloat(hRadiusOfRing), g_BeamSprite, g_HaloSprite, 0, 66, GetConVarFloat(hDurationRing), 3.7, 1.0, yourColor, 20, 0)
					TE_SendToAll();
					
					TE_SetupBeamRingPoint(f_Pos, 0.0, GetConVarFloat(hRadiusOfRing) - 6, g_BeamSprite, g_HaloSprite, 0, 66, 1.1, 1.0, 1.0, yourColor2, 150, 0)
					TE_SendToAll();
					
					new Handle:vPosition;
					TimerRepeatRing = CreateDataTimer(1.0, TimerRing, vPosition, TIMER_REPEAT | TIMER_DATA_HNDL_CLOSE)
				
					WritePackFloat(vPosition, f_Pos[0]);
					WritePackFloat(vPosition, f_Pos[1]);
					WritePackFloat(vPosition, f_Pos[2]);
					
					new Handle:pack;
					HealTimer[client] = CreateDataTimer(1.0, Healing, pack, TIMER_REPEAT | TIMER_DATA_HNDL_CLOSE);
					IsUsing = true;
					WritePackCell(pack, client);
					WritePackFloat(pack, f_Pos[0]);
					WritePackFloat(pack, f_Pos[1]);
					WritePackFloat(pack, f_Pos[2]);
					WritePackFloat(pack, GetEngineTime());
				}
			}
		}
	}
}

public Action:TimerRing(Handle:timer, Handle:vPosition)
{
	float vPos[3];
	ResetPack(vPosition);
	vPos[0] = ReadPackFloat(vPosition);
	vPos[1] = ReadPackFloat(vPosition);
	vPos[2] = ReadPackFloat(vPosition);
	
	TE_SetupBeamRingPoint(vPos, 0.0, GetConVarFloat(hRadiusOfRing), g_BeamSprite, g_HaloSprite, 0, 66, 1.1, 1.0, 1.0, yourColor2, 150, 0)
	TE_SendToAll();
}


public Action:Healing(Handle:timer, Handle:pack)
{
	float bPos[3], vPos[3];
	
	ResetPack(pack);
	new client = ReadPackCell(pack);
	bPos[0] = ReadPackFloat(pack);
	bPos[1] = ReadPackFloat(pack);
	bPos[2] = ReadPackFloat(pack);
	new Float:time=ReadPackFloat(pack);
	
	if(GetEngineTime() - time < GetConVarFloat(hDurationRing))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if(bIsSurvivorWitchOutBotCheck(i))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", vPos);
				float fTargetDistance = GetVectorDistance(bPos, vPos);
				
				if (fTargetDistance > GetConVarFloat(hRangeOfHeal)) continue;
				if(hEnabledThWalls)
				{
					if (!IsVisibleTo(bPos, vPos)) continue;
				}
				new HP = GetClientHealth(i);
				float HealBuf = GetEntPropFloat(i, Prop_Send, "m_healthBuffer");
				if(!IsPlayerIncaped(i))
				{
					if(HealBuf > 0)
					{
						if(HP < GetConVarInt(hMaxHealth))
						{
							SetEntProp(i, Prop_Send, "m_iHealth", HP + GetConVarInt(hHealCount), 1);
							SetEntPropFloat(client, Prop_Send, "m_healthBuffer", HealBuf - GetConVarInt(hHealCount));
						}
					}
					else if(HP < GetConVarInt(hMaxHealth))
					{
						SetEntProp(i, Prop_Send, "m_iHealth", HP + GetConVarInt(hHealCount), 1);
					}
				}
				else if(IsPlayerIncaped(i))
				{
					if(HP < GetConVarInt(hIncapMaxHeal))
					{
						SetEntProp(i, Prop_Send, "m_iHealth", HP + GetConVarInt(hIncapHealCount), 1); 
					}
				}
			}
		}
	}
	else
	{
		IsUsing = false;
		if(HealTimer[client] != INVALID_HANDLE)
		{
			KillTimer(HealTimer[client]);
			HealTimer[client] = INVALID_HANDLE;
		}
		if(TimerRepeatRing != INVALID_HANDLE)
		{
			KillTimer(TimerRepeatRing);
			TimerRepeatRing = INVALID_HANDLE;
		}
	}
}

public OnClientPutInServer(client)
{
	if(GetConVarInt(IsPlugin) != 1) return;
	SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUse);
	/*
	int SurvivorsCount = 0;
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsClientConnected(i) && !IsClientInGame(i))
		{
			SurvivorsCount++;
		}
	}
	if(SurvivorsCount == 0)
	{
		if(hHasLeftArea == false)
		{
			CreateTimer(10.0, hSetMedic, client, TIMER_FLAG_NO_MAPCHANGE)
		}
	}
	*/
}

public OnClientDisconnect(client)
{
	if(GetConVarInt(IsPlugin) != 1) return;
	SDKUnhook(client, SDKHook_WeaponCanUse, WeaponCanUse);
	
	if (HealTimer[client] != INVALID_HANDLE)
	{
		KillTimer(HealTimer[client]);
		HealTimer[client] = INVALID_HANDLE;
	}
}

/*
public Action:hSetMedic(Handle timer, client)
{
	new Healer = GetRandomClient()
	IsHealer[Healer] = true;
	GiveFunction(Healer, "pistol_magnum")
	CPrintToChatAll("%s {blue}Все игроки загрузились, выбираем медика.", prefix, Healer);
	CPrintToChatAll("%s {blue}%N \x05стал медиком", prefix, Healer);
	hHasLeftArea = true;
	IsHaveMedic = true;
}
*/

public Action:WeaponCanUse(client, weapon)
{
	if(GetConVarInt(IsPlugin) != 1) return Plugin_Continue;
	if(bIsSurvivor(client))
	{
		if(IsHealer[client])
		{
			new wepn = GetPlayerWeaponSlot(client, 1)
			if (!IsValidEntity(wepn))
			{
				return Plugin_Continue;
			}
			decl String:sWeaponEx[32];
			GetEntityClassname(wepn, sWeaponEx, sizeof(sWeaponEx));
			
			new String:sClassName[64];
			GetEntityClassname(weapon, sClassName, sizeof(sClassName));
			
			if(StrEqual(sWeaponEx, "weapon_pistol_magnum"))
			{
				if(StrEqual(sClassName, "weapon_melee") || StrEqual(sClassName, "weapon_pistol"))
				{
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Continue;
}

GetRandomClient(bool Admin, int caller = -1) 
{ 
     new indexes[MaxClients+1], players = 0; 
     for (new i = 1; i <= MaxClients; i++) 
     {
		if(Admin && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAdmin(i))
		{
			if(caller > 0)
			{
				if(i != caller)
					indexes[players++] = i;
			}
			else
				indexes[players++] = i;
		}
		else if(!Admin && IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			if(caller > 0)
			{
				if(i != caller)
					indexes[players++] = i;
			}
			else
				indexes[players++] = i;
		}
     } 
     if (players > 0) return indexes[GetRandomInt(0, players-1)]; 
     return -1; 
}

bool IsPlayerAdmin(int client)
{
	if(CheckCommandAccess(client, "", ADMFLAG_ROOT))
		return true;

	return false;
}

stock bool:IsPlayerIncaped(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

stock void GiveFunction(int client, char[] name)
{
	char sBuf[32];
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FormatEx(sBuf, sizeof sBuf, "give %s", name);
	FakeClientCommand(client, sBuf);
}

stock bool bIsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && !IsClientInKickQueue(client) && !IsFakeClient(client) && IsPlayerAlive(client);
}

stock bool bIsSurvivorWitchOutBotCheck(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && !IsClientInKickQueue(client) && IsPlayerAlive(client);
}

stock bool IsVisibleTo(float position[3], float targetposition[3])
{

	float vAngles[3], vLookAt[3];
	
	MakeVectorFromPoints(position, targetposition, vLookAt); // compute vector from start to target
	GetVectorAngles(vLookAt, vAngles); // get angles from vector for trace
	
	// execute Trace
	Handle trace = TR_TraceRayFilterEx(position, vAngles, MASK_SHOT, RayType_Infinite, _TraceFilter);
	
	bool isVisible = false;
	if (TR_DidHit(trace))
	{
		float vStart[3];
		TR_GetEndPosition(vStart, trace); // retrieve our trace endpoint
		
		if ((GetVectorDistance(position, vStart, false) + 25.0) >= GetVectorDistance(position, targetposition))
		{
			isVisible = true; // if trace ray length plus tolerance equal or bigger absolute distance, you hit the target
		}
	}
	
	return isVisible;
}

public bool _TraceFilter(int entity, int contentsMask)
{
	if (!entity || entity <= MaxClients || !IsValidEntity(entity)) // dont let WORLD, or invalid entities be hit
	{
		return false;
	}
	return true;
}