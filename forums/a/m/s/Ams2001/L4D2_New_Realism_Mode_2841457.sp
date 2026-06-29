#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define D_F "data/nr_save.txt"
#define TS 2
#define TSPEC 1

bool g_bOn = false;
char g_sFile[PLATFORM_MAX_PATH];
char g_sStartMap[64];
Handle g_hWarn = null, g_hGlow = null;
ConVar g_cvLim = null, g_cvABG = null;
bool g_bPmD[MAXPLAYERS+1], g_bHid[MAXPLAYERS+1], g_bLd[4];
char g_sCh[4][] = { "Nick_Bill", "Rochelle_Zoey", "Coach_Louis", "Ellis_Francis" };
ArrayList g_hForb;
bool g_bWaitAll = true;

char g_sNames[100][64] = {
	"Nina", "Bamena", "Kael", "Riven", "Lyra", "Jax", "Mina", "Zane", "Sora", "Vex",
	"Arin", "Bora", "Cid", "Dara", "Eon", "Fia", "Gale", "Hana", "Iro", "Juno",
	"Kiri", "Luka", "Mako", "Nori", "Omi", "Pike", "Quinn", "Raza", "Saki", "Taro",
	"Umi", "Veda", "Wren", "Xen", "Yuna", "Zeke", "Nova", "Atlas", "Luna", "Orion",
	"Echo", "Sage", "River", "Storm", "Phoenix", "Raven", "Wolf", "Bear", "Hawk", "Fox",
	"Blue Moon", "Red Sky", "Gold Sun", "Silver Star", "Dark Night", "Light Day", "Cold Wind", "Hot Fire", "Deep Sea", "High Hill",
	"Iron Heart", "Steel Soul", "Lost Wanderer", "Lone Survivor", "Brave Knight", "Swift Arrow", "Silent Blade", "Wild Spirit", "Old Oak", "Young Leaf",
	"Alpha One", "Beta Two", "Gamma Three", "Delta Four", "Omega Zero", "First Blood", "Last Breath", "Sharp Eye", "Strong Arm", "Fast Foot",
	"Ancient Dragon", "Shadow Assassin", "Crystal Maiden", "Thunder God", "Forest Spirit", "Desert Rose", "Ocean Pearl", "Mountain King", "Sky Warden", "Night Crawler",
	"Master of Fate", "Keeper of Time", "Seeker of Truth", "Bringer of Light", "Herald of Doom", "Guardian of Peace", "Wanderer of Dreams", "Slayer of Beasts", "Lord of Cinder", "King of Nothing"
};

public Plugin myinfo = { name = "New Realism Minimal", author = "Gemini", description = "", version = "6.0", url = "" };

public void OnPluginStart() {
	BuildPath(Path_SM, g_sFile, sizeof(g_sFile), D_F);
	g_cvLim = FindConVar("survivor_limit");
	g_cvABG = FindConVar("sb_all_bot_game");
	g_hForb = new ArrayList(3);
	RegAdminCmd("NR_Start", Cmd_Start, ADMFLAG_KICK, "");
	RegAdminCmd("NR_Stop", Cmd_Stop, ADMFLAG_KICK, "");
	HookEvent("round_start", E_RS); HookEvent("player_spawn", E_PS);
	HookEvent("player_death", E_PD); HookEvent("mission_lost", E_ML);
	HookEvent("finale_win", E_MW); HookEvent("map_transition", E_MW);
	HookEvent("defibrillator_used", E_DU);
}

public void OnMapStart() {
	g_hWarn = null; g_hGlow = null; BuildZR();
	for(int i=1; i<=MaxClients; i++) g_bPmD[i] = false;
	for(int i=0; i<4; i++) g_bLd[i] = false;
	if (g_cvLim) g_cvLim.SetInt(4);
	if (g_bOn && g_cvABG) g_cvABG.SetInt(1);
	g_bWaitAll = true;
	for(int i=1; i<=MaxClients; i++) if (IsClientInGame(i)) {
		SetEntityRenderMode(i, RENDER_NORMAL); SetEntityRenderColor(i, 255, 255, 255, 255);
	}
	if (!g_bOn && FileExists(g_sFile)) {
		KeyValues k = new KeyValues("NR");
		if (k.ImportFromFile(g_sFile) && k.GetNum("On", 0) == 1) {
			g_bOn = true;
			k.GetString("StartMap", g_sStartMap, sizeof(g_sStartMap), "");
			if (g_cvABG) g_cvABG.SetInt(1);
			if (!g_hGlow) g_hGlow = CreateTimer(0.5, T_Glow, _, TIMER_REPEAT);
		}
		delete k;
	}
	if (g_bOn && !g_hGlow) g_hGlow = CreateTimer(0.5, T_Glow, _, TIMER_REPEAT);
}

void BuildZR() {
	g_hForb.Clear(); ArrayList h = new ArrayList(3); float p[3];
	int startCnt = 0, landCnt = 0, doorCnt = 0;
	
	// 1. Điểm hồi sinh/bắt đầu (Luôn chặn)
	int e = FindEntityByClassname(-1, "info_survivor_position");
	if (e == -1) e = FindEntityByClassname(-1, "info_player_start");
	if (e != -1) { GetEntPropVector(e, Prop_Send, "m_vecOrigin", p); h.PushArray(p); g_hForb.PushArray(p); startCnt++; }
	
	// 2. Landmark (Chỉ chặn nếu KHÔNG PHẢI map Finale)
	bool isFinale = (FindEntityByClassname(-1, "trigger_finale") != -1);
	if (!isFinale) {
		e = -1; while((e = FindEntityByClassname(e, "info_landmark")) != -1) { GetEntPropVector(e, Prop_Send, "m_vecOrigin", p); h.PushArray(p); g_hForb.PushArray(p); landCnt++; }
	}
	
	// 3. Cửa Saferoom (Luôn chặn)
	e = -1; while((e = FindEntityByClassname(e, "prop_door_rotating_checkpoint")) != -1) { GetEntPropVector(e, Prop_Send, "m_vecOrigin", p); h.PushArray(p); g_hForb.PushArray(p); doorCnt++; }
	

	if (h.Length > 0) {
		char s[][] = { "weapon_first_aid_kit_spawn", "weapon_ammo_spawn", "weapon_pain_pills_spawn" };
		for(int c=0; c<sizeof(s); c++) {
			e = -1; while((e = FindEntityByClassname(e, s[c])) != -1) {
				float ip[3]; GetEntPropVector(e, Prop_Send, "m_vecOrigin", ip);
				for(int i=0; i<h.Length; i++) {
					float sp[3]; h.GetArray(i, sp);
					if (GetVectorDistance(sp, ip) < 500.0) { g_hForb.PushArray(ip); break; }
				}
			}
		}
	}
	delete h;
}

public Action T_Glow(Handle t) {
	if (!g_bOn) { g_hGlow = null; return Plugin_Stop; }
	bool b = false; for(int i=1; i<=MaxClients; i++) if (IsClientInGame(i) && GetClientTeam(i) == TS && IsPlayerAlive(i)) {
		int a = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
		if (a != -1) { char c[64]; GetEdictClassname(a, c, sizeof(c)); if (StrEqual(c, "weapon_defibrillator")) { b = true; break; } }
	}
	int e = -1; while((e = FindEntityByClassname(e, "survivor_death_model")) != -1) {
		if (b) { SetEntProp(e, Prop_Send, "m_iGlowType", 3); SetEntProp(e, Prop_Send, "m_nGlowRange", 99999); SetEntProp(e, Prop_Send, "m_nGlowRangeMin", 0); SetEntProp(e, Prop_Send, "m_glowColorOverride", 255); }
		else SetEntProp(e, Prop_Send, "m_iGlowType", 0);
		ChangeEdictState(e, GetEntSendPropOffs(e, "m_iGlowType"));
	}
	return Plugin_Continue;
}

public void E_RS(Event e, const char[] n, bool db) { if (g_bOn && g_cvLim) g_cvLim.SetInt(4); }

public void E_PS(Event e, const char[] n, bool db) {
	if (!g_bOn) return; int c = GetClientOfUserId(e.GetInt("userid"));
	if (c > 0 && IsClientInGame(c) && GetClientTeam(c) == TS) {
		PFH(c); CreateTimer(0.5, T_App, GetClientUserId(c));
	}
}

bool AppD(int c) {
	int id = GetEntProp(c, Prop_Send, "m_survivorCharacter"); if (id < 0 || id > 3) return false;
	if (g_bLd[id] || !FileExists(g_sFile)) return true;
	
	KeyValues k = new KeyValues("NR"); if (!k.ImportFromFile(g_sFile)) { delete k; return true; }
	if (!k.JumpToKey(g_sCh[id], false)) { delete k; return true; }

	// Áp dụng tên nếu nhân vật này đã được đổi tên trước đó
	char cn[64]; k.GetString("Name", cn, sizeof(cn), "");
	if (cn[0] != '\0' && !IsFakeClient(c)) {
		SetClientInfo(c, "name", cn);
		SetEntPropString(c, Prop_Data, "m_szNetname", cn);
	}

	char s[16]; k.GetString("S", s, sizeof(s), "A");
	if (StrEqual(s, "D")) {
		if (!g_bHid[c]) {
			TV(c, false);
			SetEntityMoveType(c, MOVETYPE_NONE);
			SetEntProp(c, Prop_Data, "m_takedamage", 0);
			g_bHid[c] = true;
		}
		bool hOA = false;
		for(int i=0; i<4; i++) {
			if (i == id) continue;
			k.Rewind(); if (k.JumpToKey(g_sCh[i], false)) {
				char st[16]; k.GetString("S", st, sizeof(st), "A");
				if (StrEqual(st, "A")) { hOA = true; break; }
			}
		}
		k.Rewind(); k.JumpToKey(g_sCh[id], false);
		if (GetEntityFlags(c) & FL_FROZEN) { delete k; return false; }
		if (!IsReadyToKill()) { delete k; return false; }
		
		// Tạo tên mới nếu nhân vật chết lần đầu và chưa có tên
		if (cn[0] == '\0' && !IsFakeClient(c)) {
			strcopy(cn, sizeof(cn), g_sNames[GetRandomInt(0, 99)]);
			k.SetString("Name", cn);
			k.Rewind(); k.ExportToFile(g_sFile);
			SetClientInfo(c, "name", cn);
			SetEntPropString(c, Prop_Data, "m_szNetname", cn);
		}

		TV(c, true); SetEntityMoveType(c, MOVETYPE_WALK); SetEntProp(c, Prop_Data, "m_takedamage", 2);
		g_bPmD[c] = true; SDBFR(c); delete k; g_bLd[id] = true; return true;
	}
	if (GetEntityFlags(c) & FL_FROZEN) { delete k; return false; }
	TV(c, true); SetEntityMoveType(c, MOVETYPE_WALK); SetEntProp(c, Prop_Data, "m_takedamage", 2);
	if (k.GetNum("D", 0) == 1) {
		SWp(c); int hp = k.GetNum("H", 100); if (hp > 100) hp = 100;
		int bw = k.GetNum("BW", 0); if (k.GetNum("I", 0) == 1) {
			SetEntityHealth(c, 1); SetTempHealth(c, 0.0); CreateTimer(0.2, T_FI, GetClientUserId(c));
		} else { SetEntityHealth(c, hp); SetTempHealth(c, k.GetFloat("TH", 0.0)); }
		SetEntProp(c, Prop_Send, "m_currentReviveCount", bw); if (bw >= 2) SetEntProp(c, Prop_Send, "m_bIsOnThirdStrike", 1);
		char w[64]; for(int i=0; i<5; i++) {
			char sk[8]; Format(sk, sizeof(sk), "W%d", i); k.GetString(sk, w, sizeof(w), "");
			if (w[0] && !StrEqual(w, "None")) { GivePlayerItem(c, w); if (i == 1 && StrEqual(w, "weapon_pistol") && k.GetNum("DW", 0) == 1) GivePlayerItem(c, w); }
		}
		g_bLd[id] = true;
	}
	delete k; return true;
}

void TV(int c, bool v) {
	if (!IsClientInGame(c)) return; SetEntityRenderMode(c, v ? RENDER_NORMAL : RENDER_NONE); SetEntityRenderColor(c, 255, 255, 255, v ? 255 : 0);
	for(int i=0; i<5; i++) { int w = GetPlayerWeaponSlot(c, i); if (w != -1 && IsValidEntity(w)) { if (!v) { SDKHook(w, SDKHook_SetTransmit, H_HE); SetEntityRenderMode(w, RENDER_NONE); } else { SDKUnhook(w, SDKHook_SetTransmit, H_HE); SetEntityRenderMode(w, RENDER_NORMAL); SetEntityRenderColor(w, 255, 255, 255, 255); } } }
	int a = GetEntPropEnt(c, Prop_Send, "m_hActiveWeapon"); if (a != -1 && IsValidEntity(a)) { if (!v) { SDKHook(a, SDKHook_SetTransmit, H_HE); SetEntityRenderMode(a, RENDER_NONE); } else { SDKUnhook(a, SDKHook_SetTransmit, H_HE); SetEntityRenderMode(a, RENDER_NORMAL); SetEntityRenderColor(a, 255, 255, 255, 255); } }
}

void SDBFR(int c) {
	if (!IsClientInGame(c)) return;
	
	float p[3]; if (!FSSL(p)) {
		SetEntProp(c, Prop_Data, "m_takedamage", 2); SetEntityMoveType(c, MOVETYPE_WALK);
		if (IsFakeClient(c)) { ForcePlayerSuicide(c); CreateTimer(0.1, T_RMC, GetClientUserId(c)); } else ChangeClientTeam(c, TSPEC); return;
	}
	if (GetClientTeam(c) != TS) ChangeClientTeam(c, TS);
	TeleportEntity(c, p, NULL_VECTOR, NULL_VECTOR); SWp(c); SetEntProp(c, Prop_Data, "m_takedamage", 2); SetEntityMoveType(c, MOVETYPE_WALK); SetEntityHealth(c, 1); ForcePlayerSuicide(c); int it = GetRandomInt(1, 5); int sl[] = {0, 1, 2, 3, 4};
	for(int i=0; i<5; i++) { int r = GetRandomInt(0, 4); int t = sl[i]; sl[i] = sl[r]; sl[r] = t; }
	for(int i=0; i<it; i++) {
		char w[64]; w[0] = '\0'; int cl = -1, rs = -1; bool ic = false;
		switch(sl[i]) {
			case 0: { int r = GetRandomInt(0, 8); if (r == 0) w = "weapon_smg"; else if (r == 1) w = "weapon_smg_silenced"; else if (r == 2) w = "weapon_pumpshotgun"; else if (r == 3) w = "weapon_shotgun_chrome"; else if (r == 4) w = "weapon_rifle"; else if (r == 5) w = "weapon_rifle_ak47"; else if (r == 6) w = "weapon_autoshotgun"; else if (r == 7) w = "weapon_sniper_military"; else w = "weapon_rifle_m60"; cl = GetRandomInt(0, 50); rs = GetRandomInt(0, 360); }
			case 1: { int r = GetRandomInt(0, 3); if (r == 0) w = "weapon_pistol"; else if (r == 1) w = "weapon_pistol_magnum"; else if (r == 2) { w = "weapon_chainsaw"; ic = true; cl = GetRandomInt(1, 30); } else w = "weapon_melee"; }
			case 2: { int r = GetRandomInt(0, 2); if (r == 0) w = "weapon_molotov"; else if (r == 1) w = "weapon_pipe_bomb"; else w = "weapon_vomitjar"; }
			case 3: { int r = GetRandomInt(0, 2); if (r == 0) w = "weapon_first_aid_kit"; else if (r == 1) w = "weapon_defibrillator"; else w = "weapon_upgradepack_explosive"; }
			case 4: { int r = GetRandomInt(0, 1); if (r == 0) w = "weapon_pain_pills"; else w = "weapon_adrenaline"; }
		}
		if (w[0] == '\0') continue; float dp[3]; dp[0] = p[0] + GetRandomFloat(-20.0, 20.0); dp[1] = p[1] + GetRandomFloat(-20.0, 20.0); dp[2] = p[2] + 15.0;
		int e = CreateEntityByName(w); if (e != -1) {
			if (StrEqual(w, "weapon_melee")) { char mt[][] = {"fireaxe", "crowbar", "cricket_bat", "katana", "machete", "baseball_bat"}; DispatchKeyValue(e, "melee_script_name", mt[GetRandomInt(0, 5)]); }
			DispatchSpawn(e); TeleportEntity(e, dp, NULL_VECTOR, NULL_VECTOR);
			if (cl != -1) SetEntProp(e, Prop_Send, "m_iClip1", cl); if (rs != -1 && !ic) SetEntProp(e, Prop_Send, "m_iExtraPrimaryAmmo", rs);
		}
	}
}

bool FSSL(float r[3]) {
	ArrayList c = new ArrayList(3); char cl[][] = {"weapon_pain_pills_spawn", "weapon_rifle_spawn", "weapon_ammo_spawn", "weapon_first_aid_kit_spawn", "weapon_melee_spawn", "weapon_item_spawn", "weapon_spawn"};
	for(int i=0; i<sizeof(cl); i++) { int e = -1; while((e = FindEntityByClassname(e, cl[i])) != -1) { float p[3]; GetEntPropVector(e, Prop_Send, "m_vecOrigin", p); c.PushArray(p); } }
	
	if (c.Length == 0) { delete c; return false; }
	
	int rejectCount = 0;
	for(int i=0; i<100; i++) {
		if (c.Length == 0) break;
		int randIdx = GetRandomInt(0, c.Length - 1);
		float ip[3]; c.GetArray(randIdx, ip); c.Erase(randIdx);
		
		bool n = false;
		for(int j=0; j<g_hForb.Length; j++) { float bp[3]; g_hForb.GetArray(j, bp); if (GetVectorDistance(ip, bp) < 400.0) { n = true; break; } }
		if (n) { rejectCount++; continue; }
		
		float a = GetRandomFloat(0.0, 360.0), d = GetRandomFloat(30.0, 60.0);
		float ts[3]; ts = ip; ts[2] += 20.0; float te[3]; te[0] = ip[0] + (Cosine(DegToRad(a)) * d); te[1] = ip[1] + (Sine(DegToRad(a)) * d); te[2] = ts[2];
		Handle t = TR_TraceRayFilterEx(ts, te, MASK_SOLID, RayType_EndPoint, TEFWO); float fx = te[0], fy = te[1];
		if (TR_DidHit(t)) { float hp[3]; TR_GetEndPosition(hp, t); float dr[3]; SubtractVectors(ts, hp, dr); NormalizeVector(dr, dr); ScaleVector(dr, 15.0); AddVectors(hp, dr, hp); fx = hp[0]; fy = hp[1]; } delete t;
		float ds[3]; ds[0] = fx; ds[1] = fy; ds[2] = ip[2] + 30.0; float de[3]; de[0] = fx; de[1] = fy; de[2] = ip[2] - 100.0;
		t = TR_TraceRayFilterEx(ds, de, MASK_SOLID, RayType_EndPoint, TEFWO);
		if (TR_DidHit(t)) {
			float fp[3]; TR_GetEndPosition(fp, t); float pn[3]; TR_GetPlaneNormal(t, pn); delete t;
			if (pn[2] < 0.7) continue; fp[2] += 5.0; float ms[3] = {-16.0, -16.0, 0.0}, mx[3] = {16.0, 16.0, 36.0};
			t = TR_TraceHullFilterEx(fp, fp, ms, mx, MASK_ALL, TEFWO); bool bh = TR_DidHit(t); delete t;
			if (!bh) { 
				r = fp; 
				delete c; return true; 
			}
		} else delete t;
	}
	delete c; return false;
}

public bool TEFWO(int e, int cm) { return !(e > 0 && e <= MaxClients); }

public Action Cmd_Start(int c, int a) {
	if (g_bOn) { ReplyToCommand(c, "Mode ON"); return Plugin_Handled; }
	char gm[32]; GetConVarString(FindConVar("mp_gamemode"), gm, sizeof(gm));
	if (!StrEqual(gm, "realism", false) && !StrEqual(gm, "coop", false)) { ReplyToCommand(c, "Realism/Coop Only"); return Plugin_Handled; }
	g_bOn = true; if (g_cvLim) g_cvLim.SetInt(4); if (g_cvABG) g_cvABG.SetInt(1);
	if (!g_hGlow) g_hGlow = CreateTimer(0.5, T_Glow, _, TIMER_REPEAT);
	if (FileExists(g_sFile)) DeleteFile(g_sFile);
	GetCurrentMap(g_sStartMap, sizeof(g_sStartMap));
	KeyValues k = new KeyValues("NR"); k.SetNum("On", 1); k.SetString("StartMap", g_sStartMap); k.ExportToFile(g_sFile); delete k;
	return Plugin_Handled;
}

public Action Cmd_Stop(int c, int a) {
	g_bOn = false; if (g_hWarn) { KillTimer(g_hWarn); g_hWarn = null; } if (g_hGlow) { KillTimer(g_hGlow); g_hGlow = null; } if (g_cvLim) g_cvLim.SetInt(4);
	if (g_cvABG) g_cvABG.SetInt(0);
	if (FileExists(g_sFile)) DeleteFile(g_sFile);
	return Plugin_Handled;
}

public void E_PD(Event e, const char[] n, bool db) {
	if (!g_bOn) return; int c = GetClientOfUserId(e.GetInt("userid"));
	if (c > 0 && GetClientTeam(c) == TS && !g_hWarn && !g_bPmD[c]) g_hWarn = CreateTimer(30.0, T_WL, _, TIMER_REPEAT);
}

public Action T_WL(Handle t) {
	if (!g_bOn) { g_hWarn = null; return Plugin_Stop; } bool b = false;
	for(int i=1; i<=MaxClients; i++) if (IsClientInGame(i) && GetClientTeam(i) == TS && !IsPlayerAlive(i) && !g_bPmD[i]) { b = true; break; }
	if (!b) { g_hWarn = null; return Plugin_Stop; } return Plugin_Continue;
}

public Action T_App(Handle t, int u) { int c = GetClientOfUserId(u); if (c > 0 && IsClientInGame(c) && IsPlayerAlive(c) && GetClientTeam(c) == TS && !AppD(c)) CreateTimer(0.1, T_App, u); return Plugin_Stop; }

public void E_MW(Event e, const char[] n, bool db) { if (!g_bOn) return; if (g_hWarn) { KillTimer(g_hWarn); g_hWarn = null; } SGD(); }

void SGD() {
	KeyValues k = new KeyValues("NR"); if (FileExists(g_sFile)) k.ImportFromFile(g_sFile);
	k.SetNum("On", 1); if (g_sStartMap[0] != '\0') k.SetString("StartMap", g_sStartMap);
	for(int i=1; i<=MaxClients; i++) if (IsClientInGame(i) && GetClientTeam(i) == TS) {
		int id = GetEntProp(i, Prop_Send, "m_survivorCharacter"); if (id < 0 || id > 3) continue;
		k.Rewind(); k.JumpToKey(g_sCh[id], true); k.SetNum("D", 1);
		if (!IsPlayerAlive(i)) { k.SetString("S", "D"); k.SetString("Name", ""); }
		else {
			k.SetString("S", "A"); int hp = GetClientHealth(i); bool isI = view_as<bool>(GetEntProp(i, Prop_Send, "m_isIncapacitated"));
			if (isI) hp = 30; else if (hp <= 0) hp = 100; k.SetNum("H", hp); k.SetNum("I", isI ? 1 : 0);
			k.SetFloat("TH", GetTempHealth(i)); k.SetNum("BW", GetEntProp(i, Prop_Send, "m_currentReviveCount"));
			for(int j=0; j<5; j++) {
				int w = GetPlayerWeaponSlot(i, j); char sk[8]; Format(sk, sizeof(sk), "W%d", j);
				if (w != -1) {
					char cl[64]; GetEdictClassname(w, cl, sizeof(cl));
					if (StrEqual(cl, "weapon_melee")) { char s[64]; GetEntPropString(w, Prop_Data, "m_strMapSetScriptName", s, sizeof(s)); k.SetString(sk, s); }
					else if (StrEqual(cl, "weapon_pistol")) { k.SetString(sk, "weapon_pistol"); k.SetNum("DW", GetEntProp(w, Prop_Send, "m_hasDualWeapons")); }
					else k.SetString(sk, cl);
				} else k.SetString(sk, "None");
			}
		}
		k.GoBack();
	}
	k.ExportToFile(g_sFile); delete k;
}

public void E_ML(Event e, const char[] n, bool db) {
	if (!g_bOn) return;
	for(int i=1; i<=MaxClients; i++) if (IsClientInGame(i) && !IsFakeClient(i)) PrintHintText(i, "GAME OVER\nRESTARTING CAMPAIGN");
	if (FileExists(g_sFile)) DeleteFile(g_sFile);
	KeyValues k = new KeyValues("NR"); k.SetNum("On", 1); k.SetString("StartMap", g_sStartMap); k.ExportToFile(g_sFile); delete k;
	if (g_hWarn) { KillTimer(g_hWarn); g_hWarn = null; }
	CreateTimer(5.0, T_Restart);
}

public Action T_Restart(Handle t) {
	if (g_sStartMap[0] != '\0') ServerCommand("changelevel %s", g_sStartMap);
	return Plugin_Stop;
}

float GetTempHealth(int c) { float b = GetEntPropFloat(c, Prop_Send, "m_healthBuffer"), d = GetGameTime() - GetEntPropFloat(c, Prop_Send, "m_healthBufferTime"), h = b - (d * FindConVar("pain_pills_decay_rate").FloatValue); return h < 0.0 ? 0.0 : h; }

bool ISTK(int m, bool hOA) {
	static ConVar ab = null; if (!ab) ab = FindConVar("sb_all_bot_game"); if (ab && ab.BoolValue) return true;
	int ah = 0, ps = 0; for(int i=1; i<=MaxClients; i++) if (i != m && IsClientConnected(i) && !IsFakeClient(i)) { if (IsClientInGame(i) && GetClientTeam(i) == TS && IsPlayerAlive(i)) { int id = GetEntProp(i, Prop_Send, "m_survivorCharacter"); if (id >= 0 && id <= 3 && g_bLd[id]) ah++; else ps++; } else ps++; }
	if (ah >= 1) return true;
	if (ps >= 1) return false;
	return !hOA;
}

bool IsReadyToKill() {
	bool found[4] = {false, false, false, false};
	int aliveInSave = 0, loadedAlive = 0;
	KeyValues k = new KeyValues("NR"); if (!k.ImportFromFile(g_sFile)) { delete k; return true; }
	for(int i=0; i<4; i++) {
		k.Rewind(); if (k.JumpToKey(g_sCh[i], false)) {
			char s[16]; k.GetString("S", s, sizeof(s), "A");
			if (StrEqual(s, "A")) aliveInSave++;
		}
	}
	for(int i=1; i<=MaxClients; i++) if (IsClientInGame(i) && GetClientTeam(i) == TS) {
		int cid = GetEntProp(i, Prop_Send, "m_survivorCharacter");
		if (cid >= 0 && cid <= 3) {
			found[cid] = true;
			if (g_bLd[cid]) {
				k.Rewind(); if (k.JumpToKey(g_sCh[cid], false)) {
					char s[16]; k.GetString("S", s, sizeof(s), "A");
					if (StrEqual(s, "A")) loadedAlive++;
				}
			}
		}
	}
	delete k;
	if (!(found[0] && found[1] && found[2] && found[3])) return false;
	if (aliveInSave > 0 && loadedAlive == 0) return false;
	return true;
}

void PFH(int c) {
	int id = GetEntProp(c, Prop_Send, "m_survivorCharacter"); if (id < 0 || id > 3 || g_bLd[id] || !FileExists(g_sFile)) return;
	KeyValues k = new KeyValues("NR"); if (!k.ImportFromFile(g_sFile)) { delete k; return; }
	k.JumpToKey(g_sCh[id], false); char s[16]; k.GetString("S", s, sizeof(s), "A"); delete k;
	if (StrEqual(s, "D")) {
		TV(c, false); SetEntityMoveType(c, MOVETYPE_NONE); SetEntProp(c, Prop_Data, "m_takedamage", 0);
		g_bHid[c] = true; CreateTimer(0.2, T_RHW, GetClientUserId(c));
	}
}

public Action H_HE(int e, int c) { int o = GetEntPropEnt(e, Prop_Send, "m_hOwnerEntity"); if (o > 0 && o <= MaxClients && g_bHid[o]) return Plugin_Handled; return Plugin_Continue; }

public Action T_RHW(Handle t, int u) { int c = GetClientOfUserId(u); if (c > 0 && IsClientInGame(c) && g_bHid[c]) TV(c, false); return Plugin_Stop; }

public void E_DU(Event e, const char[] n, bool db) {
	int c = GetClientOfUserId(e.GetInt("subject"));
	if (c > 0 && IsClientInGame(c)) {
		g_bHid[c] = false; TV(c, true);
		int id = GetEntProp(c, Prop_Send, "m_survivorCharacter");
		if (id >= 0 && id <= 3) {
			g_bLd[id] = true;
			KeyValues k = new KeyValues("NR");
			if (FileExists(g_sFile)) k.ImportFromFile(g_sFile);
			k.JumpToKey(g_sCh[id], true);
			k.SetString("S", "A"); k.SetNum("H", 50); k.SetNum("D", 1);
			k.Rewind(); k.ExportToFile(g_sFile); delete k;
		}
		CreateTimer(0.2, T_FVP, GetClientUserId(c));
	}
}

public Action T_FVP(Handle t, int u) { int c = GetClientOfUserId(u); if (c > 0 && IsClientInGame(c)) { g_bHid[c] = false; TV(c, true); } return Plugin_Stop; }

void SetTempHealth(int c, float h) { SetEntPropFloat(c, Prop_Send, "m_healthBuffer", h); SetEntPropFloat(c, Prop_Send, "m_healthBufferTime", GetGameTime()); }

void SWp(int c) { int w; for(int i=0; i<5; i++) while((w = GetPlayerWeaponSlot(c, i)) != -1) { RemovePlayerItem(c, w); AcceptEntityInput(w, "Kill"); } }

public Action T_FI(Handle t, int u) { int c = GetClientOfUserId(u); if (c > 0 && IsClientInGame(c) && IsPlayerAlive(c)) SDKHooks_TakeDamage(c, 0, 0, 100.0, 32); return Plugin_Stop; }

public Action T_RMC(Handle t, int u) {
	int c = GetClientOfUserId(u); if (c <= 0 || !IsClientInGame(c)) return Plugin_Stop;
	float cp[3]; GetClientAbsOrigin(c, cp); int e = -1; while((e = FindEntityByClassname(e, "survivor_death_model")) != -1) {
		float p[3]; GetEntPropVector(e, Prop_Send, "m_vecOrigin", p); if (GetVectorDistance(cp, p) < 50.0) AcceptEntityInput(e, "Kill");
	}
	return Plugin_Stop;
}