/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>
#include <vector>
#include <sdkhooks>
#include <colors>
#include <smlib>

#define IsPlayer(%1) (1 <= %1 <= 64)
#define limitKlockow 1024
#define iloscKlockow 2
#define iloscRozszerzen 8
#define iloscPrzyciskow 25
#define iloscWlasciwosci 50

#pragma dynamic 200000

enum VelocityOverride {
	
	VelocityOvr_None = 0,
	VelocityOvr_Velocity,
	VelocityOvr_OnlyWhenNegative,
	VelocityOvr_InvertReuseVelocity
};

public Plugin:myinfo = 
{
	name = "Blockmejker preview",
	author = "diablix",
	description = "<- Description ->",
	version = "1.0",
	url = "<- URL ->"
}

new const Float:g_fBlockZRozmiar = 16.0;

new const String:g_sPrefix[] = "[Blockmejker]";
new const String:g_sPodFolder[] = "diablix";
new const String:g_sDir[] = "addons/sourcemod/data/blockmejker";

new const String:g_sKlocki[iloscKlockow][] = {
	"Platforma",
	"Bhop"
}

static const String:g_sNazwyWl[iloscKlockow][4][100] = {
	{"Brak", "Brak", "Brak", "Brak"},
	{"Zapada sie po", "Wraca po", "Brak", "Brak"}
}

static const String:g_sRozszerzenia[iloscRozszerzen][] = {
	".mdl",
	".dx80.vtx",
	".dx90.vtx",
	".phy",
	".vvd",
	".sw.vtx",
	".vmt",
	".vtf"
}

new const Float:g_fDef[iloscKlockow][4] = {
	{0.0, 0.0, 0.0, 0.0},
	{0.1, 1.0, 0.0, 0.0}
}

new const Float:g_fProg[iloscKlockow][4] = {
	{0.0, 0.0, 0.0, 0.0},
	{0.1, 0.25, 0.0, 0.0}
}

new const Float:g_fMax[iloscKlockow][4] = {
	{0.0, 0.0, 0.0, 0.0},
	{2.0, 3.0, 0.0, 0.0}
}

new g_iObj[65];
new g_iKlocek[65];
new g_iRodzaj[limitKlockow];
new g_iOldButtons[65];
new g_iEdytowany[65];
new g_iEdKey[65][4];

new Float:g_fDistance[65];
new Float:g_fAngle[65][3];
new Float:g_fDodSpeed[65];
new Float:g_fLastJump[65];
new Float:g_fProp[limitKlockow][4];
new bool:g_bZablokowana[65];
new bool:g_bNoClip[65];
new bool:g_bKlocek[limitKlockow];
new bool:g_bTouched[65];
new bool:g_bInAir[65];
new String:g_sFinalPlik[53];

new Handle:g_hBhop[limitKlockow][2];
new Handle:g_hTouched[65];
new Handle:g_hStrefy[65];
public OnPluginStart(){
	RegConsoleCmd("sm_bm", cmdGlowneMenu);
	
	RegConsoleCmd("+grab", cmdGrab);
	RegConsoleCmd("-grab", cmdUnGrab);
	
	HookEvent("round_freeze_end", H_RoundStart);
	HookEvent("player_spawn", H_PlayerSpawn);
}

public Action:H_PlayerSpawn(Handle:hEvent, const String:sName[], bool:bDontBroadcast){
	new iClid = GetEventInt(hEvent, "userid");
	new id = GetClientOfUserId(iClid);

	CreateTimer(0.1, fixNoClip, id, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:fixNoClip(Handle:hTimer, any:id){
	if(g_bNoClip[id]) ustawNoClip(id, true);
} 

public Action:H_RoundStart(Handle:hEvent, const String:sName[], bool:bDontBroadcast){
	wczytajDane();
}

public OnMapStart(){
	new String:sSciezka[50];
	
	for(new i ; i < iloscKlockow ; i++){
		FormatEx(sSciezka, sizeof sSciezka, "models/%s/%s%s", g_sPodFolder, g_sKlocki[i], g_sRozszerzenia[0]);
		//LogError("!!!!!!!!!!!!!!!!!!!! %s", sSciezka);
		PrecacheModel(sSciezka);
		
		for(new l ; l < iloscRozszerzen ; l++){
			FormatEx(sSciezka, sizeof sSciezka, "%smodels/%s/%s%s", l >= 6 ? "materials/" : "", g_sPodFolder, g_sKlocki[i], g_sRozszerzenia[l]);
			AddFileToDownloadsTable(sSciezka);
		}
	}
	
	if(!DirExists(g_sDir)){
		CreateDirectory(g_sDir, 3); 
	}
	
	decl String:sMapa[20];
	GetCurrentMap(sMapa, sizeof sMapa);
	FormatEx(g_sFinalPlik, sizeof g_sFinalPlik, "%s/%s.txt", g_sDir, sMapa);
	
	/*PrecacheModel("models/diablix/bhop.mdl");
	
	AddFileToDownloadsTable("models/diablix/bhop.mdl");
	AddFileToDownloadsTable("models/diablix/bhop.dx80.vtx");
	AddFileToDownloadsTable("models/diablix/bhop.dx90.vtx");
	AddFileToDownloadsTable("models/diablix/bhop.phy");
	AddFileToDownloadsTable("models/diablix/bhop.vvd");
	AddFileToDownloadsTable("models/diablix/bhop.sw.vtx");
	
	AddFileToDownloadsTable("materials/models/diablix/bhop.vmt");
	AddFileToDownloadsTable("materials/models/diablix/bhop.vtf");*/
}

public Float:FloatMin(Float:a, Float:b) return Float:a > b ? b : a;

public Action:OnPlayerRunCmd(iGracz, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon){
	if(g_bNoClip[iGracz]){
		buttons &= ~IN_DUCK; 
		
		return Plugin_Changed;
	}
	
	if(g_bTouched[iGracz]){
		if((buttons & IN_JUMP) && (buttons & IN_DUCK)){
			if((GetEntityFlags(iGracz) & (FL_ONGROUND)) && g_bInAir[iGracz]){
				new Float:fVel[3];
				Entity_GetAbsVelocity(iGracz, fVel);
				fVel[2] = 0.0;
				new Float:fSpeed = GetVectorLength(fVel);
				
				if(fSpeed>60.0){
					g_bTouched[iGracz] = false;
					new Float:clientEyeAngles[3];
					GetClientEyeAngles(iGracz,clientEyeAngles);
					if(buttons & IN_BACK){
						clientEyeAngles[0] += 180.0;
					}
					else{
						clientEyeAngles[0] = 0.0;
					}
					
					Client_Push(iGracz,clientEyeAngles, 100.0,VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
					
					return Plugin_Changed;
				}
				//g_bTouched[iGracz] = false;
			}
		}
	}
	
	for (new i = 0; i < iloscPrzyciskow ; i++){
		new button = (1 << i);
		
		if ((buttons & button)){
			if (!(g_iOldButtons[iGracz] & button)){
				OnButtonPress(iGracz, button);
			}
		}
		else if ((g_iOldButtons[iGracz] & button)){
			OnButtonRelease(iGracz, button);
		}
	}
    
	g_iOldButtons[iGracz] = buttons;
    
	return Plugin_Continue;
}

stock OnButtonPress(iGracz, iButton){
	return iGracz+iButton;
}

public Action:fixSpeed(Handle:hTimer, any:iGracz){
	/*new iGracz;

	ResetPack(hDane);
	iGracz = ReadPackCell(hDane);*/
		
	g_fDodSpeed[iGracz] = 0.0;
	
	g_hStrefy[iGracz] = INVALID_HANDLE;
}

OnButtonRelease(id, iButton){
	if(iButton & (IN_RIGHT|IN_LEFT)){
		if(g_bInAir[id]){
			if(g_fDodSpeed[id] < 5.0){
				g_fDodSpeed[id] -= 1.0;
			}
		}
	}
	if(iButton & IN_USE){
		new iEnt = TraceToEntity(id);
		if(JestKlockiem(iEnt)){
			//PrintToChat(id, "\x01\x0B\x06 1, Klocek:\x03 %s", g_sKlocki[g_iRodzaj[iEnt]]);
			decl String:sWl[100];
			new bool:bT = false;
			for(new i ; i < 4 ; i++){
				if(i == 0){
					Format(sWl, sizeof sWl, "{olive}[{lime}");
				}
				if(!StrEqual(g_sNazwyWl[g_iRodzaj[iEnt]][i], "Brak")){
					if(!bT) bT = true;
					
					Format(sWl, sizeof sWl, "%s %s: %.1f", sWl, g_sNazwyWl[g_iRodzaj[iEnt]][i], g_fProp[iEnt][i]);
				}
				if(i == 3){
					Format(sWl, sizeof sWl, "%s{olive} ]", sWl);
				}
			}
			if(bT){
				CPrintToChat(id, "{blue}*{lime}%s{olive} %s{lime} %s", g_sPrefix, g_sKlocki[g_iRodzaj[iEnt]], sWl);
			}
			else{
				CPrintToChat(id, "{blue}*{lime}%s{olive} %s{lime} ", g_sPrefix, g_sKlocki[g_iRodzaj[iEnt]]);
			}
			//PrintToChatAll("\x01\x0B\x04Colors!");
		}
	}
}

public OnClientDisconnect_Post(id){
    g_iOldButtons[id] = 0;
}


public OnClientPutInServer(id){
	g_fAngle[id][0] = 90.0
	g_fAngle[id][1] = 0.0
	g_fAngle[id][2] = 0.0
	g_bZablokowana[id] = true;
	
	SDKHook(id, SDKHook_Touch, SDKH_TouchGr);
	SDKHook(id, SDKHook_PreThink, ClientPreThink);
}

public Action:fixIt(Handle:hTimer, any:iGracz){
	if(g_bTouched[iGracz]){
		g_bTouched[iGracz] = false;
	}
			
	g_hTouched[iGracz] = INVALID_HANDLE;
}

public SDKH_TouchGr(iGracz, iTouched){
	if((GetEntityFlags(iGracz) & (FL_ONGROUND))) { 
		if(g_hTouched[iGracz] != INVALID_HANDLE) KillTimer(g_hTouched[iGracz]);
		
		g_bTouched[iGracz]=true;
		g_hTouched[iGracz] = CreateTimer(0.04, fixIt, iGracz);
		
		if(g_hStrefy[iGracz] != INVALID_HANDLE){ 
			KillTimer(g_hStrefy[iGracz]);
			g_hStrefy[iGracz] = CreateTimer(0.1, fixSpeed, iGracz);
		}
	}
}

public SDKH_Touch(iEnt, iTouched){
	if(IsPlayer(iTouched) && IsPlayerAlive(iTouched)){
		if(IsValidEdict(iEnt) && IsValidEntity(iEnt)){
			if(g_iRodzaj[iEnt] == 1){
				if (g_hBhop[iEnt][1] == INVALID_HANDLE){
					g_hBhop[iEnt][1] = CreateTimer(g_fProp[iEnt][0], niesolidnyKlocek, iEnt);
				}
			}
		}
	}
}

public Action:solidnyKlocek(Handle:hTimer, any:iEnt){
	/*new iEnt;

	ResetPack(hDane);
	iEnt = ReadPackCell(hDane);*/
	
	if(IsValidEntity(iEnt)){
		SetEntProp(iEnt, Prop_Send, "m_nSolidType", 6);
		SetEntityRenderMode(iEnt, RENDER_NORMAL);
		
		g_hBhop[iEnt][0] = INVALID_HANDLE;
	}
}

public Action:niesolidnyKlocek(Handle:hTimer, any:iEnt){
	if(IsValidEntity(iEnt)){
		SetEntProp(iEnt, Prop_Send, "m_nSolidType", 0);
		SetEntityRenderMode(iEnt, RENDER_TRANSALPHA);
		SetEntityRenderColor(iEnt, 255, 255, 255, 64);
		
		if (g_hBhop[iEnt][0] == INVALID_HANDLE){
			g_hBhop[iEnt][0] = CreateTimer(g_fProp[iEnt][1], solidnyKlocek, iEnt);
		}
		
		g_hBhop[iEnt][1] = INVALID_HANDLE;
	}
}

public Action:cmdGrab(id, args){  
	if (!IsPlayerAlive(id))
		return Plugin_Handled;

	new ent = TraceToEntity(id);
	if (ent==-1)
		return Plugin_Handled;

	new String:edictname[128];
	GetEdictClassname(ent, edictname, 128);
	if (strncmp("prop_", edictname, 5, false)==0){
		AcceptEntityInput(ent, "EnableMotion");
			
		GetEntPropVector(ent, Prop_Data, "m_angRotation", g_fAngle[id]); 
			
		new Float:fOrg[2][3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", fOrg[0]);
		GetEntPropVector(id, Prop_Send, "m_vecOrigin", fOrg[1]);
		new Float:distance = GetVectorDistance(fOrg[0], fOrg[1]);

		g_iObj[id] = ent;
		g_fDistance[id] = distance;
	}

	return Plugin_Handled;
}

public cmdChuj(id, iEnt){
	new Float:fOri[3], Float:fAngles[3], Float:fOrigin[3];
	GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", fOri);
	
	fOri[0] += 65.5;

	new Handle:trace = TR_TraceRayFilterEx(fOri, fAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
   
	if(TR_DidHit(trace))
	{
		new TRIndex = TR_GetEntityIndex(trace);
		
		if(JestKlockiem(TRIndex)){
			TR_GetEndPosition(fOrigin, trace);
			
			if(FloatAbs(fOrigin[0]-fOri[0]) <= 1.0){
				GetEntPropVector(TRIndex, Prop_Send, "m_vecOrigin", fOri);
				fOri[0] -= 65.5;
				PrintToChatAll("Sklejono!");
				TeleportEntity(iEnt, fOri, NULL_VECTOR, NULL_VECTOR);
				
				return 1;
			}
		}
    }
	CloseHandle(trace);
	
	return 0;
}

public Action:cmdUnGrab(id, args){
	if (!IsPlayerAlive(id)) return Plugin_Handled;
	if(!JestKlockiem(g_iObj[id])) return Plugin_Handled;
	AcceptEntityInput(g_iObj[id], "DisableMotion");

	TeleportEntity(g_iObj[id], NULL_VECTOR, g_bZablokowana[id] ? g_fAngle[id] : NULL_VECTOR, NULL_VECTOR); 
	g_iObj[id] = -1; 
	
	return Plugin_Handled;
}

public ClientPreThink(i){
	new Float:vecDir[3], Float:vecPos[3], Float:vecVel[3];
	new Float:viewang[3];
	new Float:speed = 10.0;
	//jebany geniusz ze mnie
	if(GetGameTime() - g_fLastJump[i] >= 0.2){
		if(GetEntityFlags(i) & FL_ONGROUND){
			g_bInAir[i] = false;
		}
		else{
			g_bInAir[i] = true;
			
			if(g_hStrefy[i] != INVALID_HANDLE){ KillTimer(g_hStrefy[i]); }
		}
		g_fLastJump[i] = GetGameTime();
	}
	
	//SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", g_bNoClip[i] ? 100.0 : 320.0);
	//PrintToChatAll("%d", _:g_bTouched[i]);
	if (g_iObj[i]>0){
		if (IsValidEdict(g_iObj[i]) && IsValidEntity(g_iObj[i])){
			new Float:distance = g_fDistance[i];
			
			GetClientEyeAngles(i, viewang);
			GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
			
			GetClientEyePosition(i, vecPos);
			
			vecPos[0]+=vecDir[0]*distance;
			vecPos[1]+=vecDir[1]*distance;
			vecPos[2]+=vecDir[2]*distance;
			
			GetEntPropVector(g_iObj[i], Prop_Send, "m_vecOrigin", vecDir);
			
			SubtractVectors(vecPos, vecDir, vecVel);
			ScaleVector(vecVel, speed);
			
			TeleportEntity(g_iObj[i], NULL_VECTOR, g_bZablokowana[i] ? g_fAngle[i] : NULL_VECTOR, NULL_VECTOR); 
			
			/*new iEnt = g_iObj[i];
				
			new Float:fOri[3], Float:fAngles[3], Float:fOrigin[3];
			GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", fOri);
			//GetEntPropVector(iEnt, Prop_Data, "m_angRotation", fAngles); 
			//fAngles[0] -= 90.0;
			//fOri[0] += 65.5;
				
			new Handle:trace = TR_TraceRayFilterEx(fOri, fAngles, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, iEnt);
				
			if(TR_DidHit(trace)) {
				TR_GetEndPosition(fOrigin, trace);
				GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", fOri);
				PrintToChatAll("%f | %f", FloatAbs(fOrigin[0])-FloatAbs(fOri[0]), vecVel[0]);
				new Float:fOdleglosc = FloatAbs(fOrigin[0]) - FloatAbs(fOri[0]);
				new TRIndex = TR_GetEntityIndex(trace);
					
				if(JestKlockiem(TRIndex)){
					TR_GetEndPosition(fOrigin, trace);
						
					if((fOdleglosc >= 30.0) && (fOdleglosc <= 34.0) && vecVel[0] > 0.0){
							//TeleportEntity(iEnt, NULL_VECTOR, g_bZablokowana[i] ? g_fAngle[i] : NULL_VECTOR, NULL_VECTOR); 
						new Float:fAngle[3];
						GetEntPropVector(TRIndex, Prop_Data, "m_angRotation", fAngle); 
						GetEntPropVector(TRIndex, Prop_Send, "m_vecOrigin", fOri);
						fOri[0] -= 65.5;
							//PrintToChatAll("Sklejono!");
						TeleportEntity(iEnt, fOri, g_bZablokowana[i] ? g_fAngle[i] : NULL_VECTOR, NULL_VECTOR);
							
						CloseHandle(trace);
							
						return 1;
					}
				}
			}
			CloseHandle(trace);*/


			TeleportEntity(g_iObj[i], NULL_VECTOR, g_bZablokowana[i] ? g_fAngle[i] : NULL_VECTOR, vecVel); 
			
			//TeleportEntity(g_iObj[i], NULL_VECTOR, g_bZablokowana[i] ? g_fAngle[i] : NULL_VECTOR, vecVel); 
			//cmdChuj(i, g_iObj[i])
			//cmdChuj(i, g_iObj[i]);
		}
		else{
			g_iObj[i]=-1;
		}
		
	}
}

public cmdEdycjaMenu(id){
	new Handle:menu = CreateMenu(MenuEdycjaHandle);
	SetMenuTitle(menu, "[diablix] BlockMaker v0.1 alpha");
	
	new iRodzaj = g_iRodzaj[g_iEdytowany[id]];
	decl String:sChoice[9], String:sWl[50];
	
	for(new i ; i < 4 ; i++){
		g_iEdKey[id][i] = 0;
		
		if(!StrEqual(g_sNazwyWl[iRodzaj][i], "Brak")){
			FormatEx(sWl, sizeof sWl, "%s: %.1f", g_sNazwyWl[iRodzaj][i], g_fProp[g_iEdytowany[id]][i]);
		}
		else{
			FormatEx(sWl, sizeof sWl, "%s", g_sNazwyWl[iRodzaj][i]);
			g_iEdKey[id][i] = 1;
		}
		FormatEx(sChoice, sizeof sChoice, "#choice%d", i+1);
		AddMenuItem(menu, sChoice, sWl);
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, id, 0);
}

public MenuEdycjaHandle(Handle:menu, MenuAction:action, id, iOpcja){
	if (action == MenuAction_Select){
		if(JestKlockiem(g_iEdytowany[id])){
			new i = iOpcja;
			new iRodzaj = g_iRodzaj[g_iEdytowany[id]];
			
			if(!g_iEdKey[id][i]){
				if(g_fProp[g_iEdytowany[id]][i] >= g_fMax[iRodzaj][i]){
					g_fProp[g_iEdytowany[id]][i] = g_fDef[iRodzaj][i];
				}
				else{
					g_fProp[g_iEdytowany[id]][i] += g_fProg[iRodzaj][i];
				}
				CPrintToChat(id, "{blue}*{lime}%s{olive} Sukces!", g_sPrefix);
			}
			cmdEdycjaMenu(id);
		}
		else{
			CPrintToChat(id, "{blue}*{lime}%s{olive} Blad! Edytowany klocek zostal usuniety!", g_sPrefix);
			cmdGlowneMenu(id, 0);
		}
		
	}
	else if (action == MenuAction_Cancel){
		cmdGlowneMenu(id, 0)
	}
	else if (action == MenuAction_End){
		CloseHandle(menu);
	}
}

public cmdOsieMenu(id){
	new Handle:menu = CreateMenu(MenuOsieHandle);
	SetMenuTitle(menu, "[diablix] BlockMaker v0.1 alpha");
	AddMenuItem(menu, "#choice1", "X - 5 stopni");
	AddMenuItem(menu, "#choice2", "X + 5 stopni");
	AddMenuItem(menu, "#choice3", "Y - 5 stopni");
	AddMenuItem(menu, "#choice4", "Y + 5 stopni");
	AddMenuItem(menu, "#choice5", "Z - 5 stopni");
	AddMenuItem(menu, "#choice6", "Z + 5 stopni");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, id, 0);
}

public MenuOsieHandle(Handle:menu, MenuAction:action, id, iOpcja){
	if (action == MenuAction_Select){	
		new iEnt = TraceToEntity(id);
		if(JestKlockiem(iEnt)){
			new Float:fAngle[3];
			GetEntPropVector(iEnt, Prop_Data, "m_angRotation", fAngle); 
			
			AcceptEntityInput(iEnt, "DisableMotion");
					
			switch(iOpcja){
				case 0,1:{
					fAngle[0] -= (iOpcja == 0 ? 5.0 : -5.0);
				}
				case 2,3:{
					fAngle[1] -= (iOpcja == 2 ? 5.0 : -5.0);
				}
				case 4,5:{
					fAngle[2] -= (iOpcja == 4 ? 5.0 : -5.0);
				}
			}
			TeleportEntity(iEnt, NULL_VECTOR, fAngle, NULL_VECTOR);
			CPrintToChat(id, "{blue}*{lime}%s{olive} Sukces! Zmieniono kat nachylenia o 5 stopni!", g_sPrefix);
		}
		else{
			CPrintToChat(id, "{blue}*{lime}%s{olive} To narzedzie dziala tylko na klocki!", g_sPrefix);
		}
		cmdOsieMenu(id);
	}
	else if (action == MenuAction_Cancel){
		cmdFizykaMenu(id)
	}
	else if (action == MenuAction_End){
		CloseHandle(menu);
	}
}

public MenuGlowneHandle(Handle:menu, MenuAction:action, id, iOpcja){
	if (action == MenuAction_Select){
		switch(iOpcja+1){
			case 1:{
				cmdKlockiMenu(id);
			}
			case 2:{
				new Float:fOrigin[3];
				GetAimOrigin(id, fOrigin);
					
				fOrigin[2] += g_fBlockZRozmiar
				
				stworzKlocek(id, g_iKlocek[id], fOrigin, true);
				CPrintToChat(id, "{blue}*{lime}%s{olive} Udalo sie stworzyc klocek!", g_sPrefix);
				cmdGlowneMenu(id, 0)
			}
			case 3:{
				new iEnt = TraceToEntity(id);
				if(JestKlockiem(iEnt)){
					CPrintToChat(id, "{blue}*{lime}%s{olive} Klocek o id. %d zostal usuniety!", g_sPrefix, iEnt);
					g_bKlocek[iEnt] = false;
					RemoveEdict(iEnt);
				}
				else{
					CPrintToChat(id, "{blue}*{lime}%s{olive} Najedz na klocek aby go usunac!", g_sPrefix);
				}
				cmdGlowneMenu(id, 0);

			}
			case 4:{
				cmdFizykaMenu(id);
			}
			case 5:{
				//g_bNoClip[id] = !g_bNoClip[id];
				//ustawNoClip(id, g_bNoClip[id]);
				cmdGlowneMenu(id, 0);
				
				new iEnt = TraceToEntity(id);
				cmdChuj(id, iEnt)
				
			}
			case 6:{
				new iEnt = TraceToEntity(id);
				if(JestKlockiem(iEnt)){
					g_iEdytowany[id] = iEnt;
					cmdEdycjaMenu(id);
					return 1;
				}
				CPrintToChat(id, "{blue}*{lime}%s{olive} Najedz na klocek aby go edytowac!", g_sPrefix);
				cmdGlowneMenu(id, 0);
			}
			//PrintToConsole(id, "You selected item: %d (found? %d info: %s)", iOpcja, found, info);
		}
	}
	else if (action == MenuAction_Cancel){
	}
	else if (action == MenuAction_End){
		CloseHandle(menu);
	}
	return 1;
}

public Action:cmdGlowneMenu(id, args){
	new Handle:menu = CreateMenu(MenuGlowneHandle);
	decl String:sBlokada[20];
	FormatEx(sBlokada, (sizeof sBlokada), "%s", g_sKlocki[g_iKlocek[id]]);
	SetMenuTitle(menu, "[diablix] BlockMaker v0.1 alpha");
	AddMenuItem(menu, "#choice1", sBlokada);
	AddMenuItem(menu, "#choice2", "Stworz klocek");
	AddMenuItem(menu, "#choice3", "Usun klocek");
	AddMenuItem(menu, "#choice4", "Opcje i fizyka");
	FormatEx(sBlokada, (sizeof sBlokada), "NoClip: %s", g_bNoClip[id] ? "Tak" : "Nie");
	AddMenuItem(menu, "#choice5", sBlokada);
	AddMenuItem(menu, "#choice6", "Edytuj nakierowany klocek");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, id, 0);
 
	return Plugin_Handled;
}

public Action:cmdFizykaMenu(id){
	new Handle:menu = CreateMenu(MenuFizykaHandle);
	decl String:sBlokada[20];
	SetMenuTitle(menu, "[diablix] BlockMaker v0.1 alpha");
	AddMenuItem(menu, "#choice1", "Wyzeruj nachylenie klocka");
	FormatEx(sBlokada, (sizeof sBlokada), "%s fizyke", g_bZablokowana[id] ? "Odblokuj" : "Zablokuj");
	AddMenuItem(menu, "#choice2", sBlokada);
	AddMenuItem(menu, "#choice3", "Edytuj katy nachylenia");
	AddMenuItem(menu, "#choice4", "Zapisz dane");

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, id, 0);
 
	return Plugin_Handled;
}

public MenuFizykaHandle(Handle:menu, MenuAction:action, id, iOpcja){
	if (action == MenuAction_Select){
		switch(iOpcja+1){
			case 1:{
					g_fAngle[id][0] = 90.0;
					g_fAngle[id][1] = 0.0;
					g_fAngle[id][2] = 0.0;
					
					CPrintToChat(id, "{blue}*{lime}%s{olive} Nachylenie klocka zostalo wyzerowane!", g_sPrefix);
					new iEnt = TraceToEntity(id);
					if(JestKlockiem(iEnt)){
						TeleportEntity(iEnt, NULL_VECTOR, g_fAngle[id], NULL_VECTOR);
					}
					
					cmdFizykaMenu(id);
			}
			/*case 2:{
				new iEnt = TraceToEntity(id);
				if(JestKlockiem(iEnt)){
					GetEntPropVector(iEnt, Prop_Data, "m_angRotation", g_fAngle[id]); 
					
					PrintToChat(id, "%s Kat nachylenia zostal zapamietany! Wszystkie klocki beda posiadaly okreslone nachylenie!", g_sPrefix);
				}
				else{
					PrintToChat(id, "%s Najedz na klocek aby zapamietac jego kat nachylenia!", g_sPrefix);
				}
				cmdFizykaMenu(id);
			}*/
			case 2:{
				g_bZablokowana[id] = !g_bZablokowana[id];
				CPrintToChat(id, "{blue}*{lime}%s{olive} Przesuwane klocki posiadaja teraz %s fizyke!", g_sPrefix, g_bZablokowana[id] ? "ZABLOKOWANA" : "ODBLOKOWANA");
				
				cmdFizykaMenu(id);
			}
			case 3:{
				cmdOsieMenu(id);
			}
			case 4:{
				zapiszDane(id);
				cmdFizykaMenu(id);
			}
		}
	}
	else if (action == MenuAction_Cancel){
		cmdGlowneMenu(id, 0);
	}
	else if (action == MenuAction_End){
		CloseHandle(menu);
	}
}

public MenuKlockiHandle(Handle:menu, MenuAction:action, id, iOpcja){
	if (action == MenuAction_Select){
		if(iOpcja < iloscKlockow){
			g_iKlocek[id] = iOpcja;
			
			CPrintToChat(id, "{blue}*{lime}%s{olive} Wybrales klocek:{blue} %s", g_sPrefix, g_sKlocki[iOpcja]);
			
			cmdGlowneMenu(id, 0);
		}
		else{
			CPrintToChat(id, "{blue}*{lime}%s{olive} Blad!", g_sPrefix);
			
			cmdKlockiMenu(id);
		}
	}
	else if (action == MenuAction_Cancel){
		cmdGlowneMenu(id, 0);
	}
	else if (action == MenuAction_End){
		CloseHandle(menu);
	}
}

public Action:cmdKlockiMenu(id){
	new Handle:menu = CreateMenu(MenuKlockiHandle);
	SetMenuTitle(menu, "[diablix] BlockMaker v0.1 alpha");
	
	decl String:sKlocek[15];
	decl String:sOpcja[9];
	
	for(new i ; i < iloscKlockow ; i++){
		FormatEx(sKlocek, sizeof sKlocek, g_sKlocki[i]);
		FormatEx(sOpcja, sizeof sOpcja, "#choice%d", i+1);
		AddMenuItem(menu, sOpcja, sKlocek);
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, id, 0);
 
	return Plugin_Handled;
}

public Action:wczytajDane(){
	if(!FileExists(g_sFinalPlik)) return Plugin_Handled;
	
	new Handle:iWskDoPliku = OpenFile(g_sFinalPlik, "r");
	
	decl String:sDane[1024];
	decl String:sData[iloscWlasciwosci][75];
	new iMax = 0;
	new iData[iloscWlasciwosci];
	new Float:fData[iloscWlasciwosci];
	new Float:fOri[3];
	new Float:fAng[3];
	
	while(!IsEndOfFile(iWskDoPliku) && ReadFileLine(iWskDoPliku, sDane, sizeof sDane)){
		TrimString(sDane);
		if(!strlen(sDane)) continue;
		
		StripQuotes(sDane);

		parsuj(sDane, sizeof sDane, sData)
		
		for(new i = 0; i < iloscWlasciwosci ; i ++){
			if(!strlen(sData[i])) iMax = i;
		}
		
		for(new l = 0; l < iMax ; l++){
			switch(l){
				case 0:{
					iData[l] = StringToInt(sData[l]);
				}
				default:{
					fData[l] = StringToFloat(sData[l]);
				}
			}
		}
		
		for(new f = 0 ; f < 3 ; f++){
			fOri[f] = fData[f+1];
			fAng[f] = fData[f+4];
		}
		
		new iEnt = stworzKlocek(0, iData[0], fOri);
		
		TeleportEntity(iEnt, fOri, fAng, NULL_VECTOR);
		
		
	}
	return Plugin_Continue;
	
}

stock parsuj(String:sZrodlo[], iZrodloLen, String:sOutput[][]){
	new iLiczZnaki = 0;
	new iZnalezione = 0;
	new iLast = 0;
	
	for(new i = 0 ; i < iZrodloLen ; i++){
		if(sZrodlo[i] != '@'){
			iLiczZnaki++;
		}
		else{
			for(new b ; b <= iLiczZnaki ; b++){
				if(iZnalezione==0){
					sOutput[iZnalezione][b] = sZrodlo[b];
					//PrintToChatAll("%d", strlen(sOutput[c]));
				}
				else{
					sOutput[iZnalezione][b] = sZrodlo[(b+iLast)+iZnalezione];
				}
				
			}
			ReplaceString(sOutput[iZnalezione], 75, "@", "");
			//TrimString(sOutput[iZnalezione]);
			iLast += strlen(sOutput[iZnalezione]);
			iLiczZnaki = 0;
			iZnalezione+=1;
		}
		
	}
	return iZnalezione;
}

public zapiszDane(id){
	DeleteFile(g_sFinalPlik);
	new Handle:iWskDoPliku = OpenFile(g_sFinalPlik, "w");
	new iIle;
	for(new iEnt ; iEnt < GetMaxEntities() ; iEnt++){
		if(JestKlockiem(iEnt)){
			new String:edictname[128];
			GetEdictClassname(iEnt, edictname, 128);
			if(strncmp("prop_", edictname, 5, false)==0){
				new Float:fAngle[3], Float:fOrigin[3];
				GetEntPropVector(iEnt, Prop_Data, "m_angRotation", fAngle); 
				GetEntPropVector(iEnt, Prop_Data, "m_vecOrigin", fOrigin);
				WriteFileLine(iWskDoPliku, "%d@%f@%f@%f@%f@%f@%f@", g_iRodzaj[iEnt], fOrigin[0], fOrigin[1], fOrigin[2], fAngle[0], fAngle[1], fAngle[2]);
				
				iIle++;
			}
		}
	}
	CPrintToChat(id, "{blue}*{lime}%s{olive} Zapisales{blue} %d{olive} klockow!", g_sPrefix, iIle);
	CloseHandle(iWskDoPliku);
}

stock stworzKlocek(id, iKtory, Float:fOrigin[3], bool:bGracz=false){
	new iEnt = CreateEntityByName("prop_physics_override"); 
	if(iEnt != -1){
		decl String:sKtory[55];
		FormatEx(sKtory, sizeof sKtory, "models/%s/%s%s", g_sPodFolder, g_sKlocki[iKtory], g_sRozszerzenia[0]);
		SetEntityModel(iEnt, sKtory);
		DispatchSpawn(iEnt);
		ActivateEntity(iEnt);

		TeleportEntity(iEnt, fOrigin, NULL_VECTOR, NULL_VECTOR);
			
		SetEntProp(iEnt, Prop_Send, "m_nSolidType", 6);
		SetEntProp(iEnt, Prop_Send, "m_CollisionGroup", 5);
		
		AcceptEntityInput(iEnt, "DisableMotion");
		
		if(bGracz){
			TeleportEntity(iEnt, NULL_VECTOR, Float:{90.0, 0.0, 0.0}, NULL_VECTOR); 
			TeleportEntity(iEnt, NULL_VECTOR, g_bZablokowana[id] ? g_fAngle[id] : NULL_VECTOR, NULL_VECTOR); 
		}
			
		SDKHook(iEnt, SDKHook_Touch, SDKH_Touch);
		
		g_bKlocek[iEnt] = true;
		g_iRodzaj[iEnt] = iKtory;
		
		for(new i ; i < 4 ; i++){
			 g_fProp[iEnt][i] = g_fDef[iKtory][i];
		}
		
		return iEnt;
	}
	return -1;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask) {
    return entity > GetMaxClients();
} 

public bool:TraceRayDontHitSelf(entity, mask, any:data){
	if(entity == data){
		return false; 
	}
	return true;
}

stock GetAimOrigin(id, Float:hOrigin[3]) 
{
    new Float:vAngles[3], Float:fOrigin[3];
    GetClientEyePosition(id,fOrigin);
    GetClientEyeAngles(id, vAngles);

    new Handle:trace = TR_TraceRayFilterEx(fOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

    if(TR_DidHit(trace)) 
    {
        TR_GetEndPosition(hOrigin, trace);
        CloseHandle(trace);
        return 1;
    }

    CloseHandle(trace);
    return 0;
}

stock TraceToEntity(id){
	new Float:vecClientEyePos[3], Float:vecClientEyeAng[3];
	GetClientEyePosition(id, vecClientEyePos);
	GetClientEyeAngles(id, vecClientEyeAng); 
	
	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, id);
	if (TR_DidHit(INVALID_HANDLE)){
		new TRIndex = TR_GetEntityIndex(INVALID_HANDLE);
		return TRIndex;
	}
  
	return -1;
}


stock bool:JestKlockiem(iEnt){
	if(IsValidEdict(iEnt) && IsValidEntity(iEnt) && g_bKlocek[iEnt]) return true;
	
	return false;
}

stock ustawNoClip(id, bool:bNoClip){
		SetEntProp(id, Prop_Send, "movetype", bNoClip ? 8 : 1);
}

stock Client_Push(client, Float:clientEyeAngle[3], Float:power, VelocityOverride:override[3]=VelocityOvr_None)
{
	decl Float:forwardVector[3],
	Float:newVel[3];
	
	GetAngleVectors(clientEyeAngle, forwardVector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(forwardVector, forwardVector);
	ScaleVector(forwardVector, power);
	
	Entity_GetAbsVelocity(client,newVel);
	
	for(new i=0;i<3;i++){
		switch(override[i]){
			case VelocityOvr_Velocity:{
				newVel[i] = 0.0;
			}
			case VelocityOvr_OnlyWhenNegative:{				
				if(newVel[i] < 0.0){
					newVel[i] = 0.0;
				}
			}
			case VelocityOvr_InvertReuseVelocity:{				
				if(newVel[i] < 0.0){
					newVel[i] *= -1.0;
				}
			}
		}
		
		newVel[i] += forwardVector[i];
	}
	
	Entity_SetAbsVelocity(client,newVel);
}