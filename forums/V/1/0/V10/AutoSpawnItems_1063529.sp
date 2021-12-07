/*
 * Items List: 
 * weapon_adrenaline, weapon_autoshotgun, weapon_chainsaw, weapon_defibrillator, weapon_fireworkcrate, 
 * weapon_first_aid_kit, weapon_gascan, weapon_gnome, grenade_launcher, weapon_hunting_rifle, 
 * weapon_molotov, weapon_oxygentank, weapon_pain_pills, weapon_pipe_bomb, weapon_pistol, 
 * weapon_pistol_magnum, weapon_propanetank, weapon_pumpshotgun, weapon_rifle, weapon_rifle_ak47, 
 * weapon_rifle_desert, weapon_rifle_sg552, weapon_shotgun_chrome, shotgun_spas, weapon_smg, 
 * weapon_smg_mp5, weapon_smg_silenced, weapon_sniper_awp, sniper_military, weapon_sniper_scout, 
 * weapon_vomitjar, weapon_ammo_spawn, weapon_upgradepack_explosive, weapon_upgradepack_incendiary, 
 * weapon_cola_bottles weapon_rifle_m60
 *
 * ####
 * Melee Weapons List:
 * baseball_bat, cricket_bat, crowbar, electric_guitar, fireaxe, frying_pan, 
 * katana, machete, tonfa, knife
 */

#include <sourcemod>
#include <sdktools>

#define VERSION "1.7"
#define CONFIG_FILE "data/AutoItemsSpawn.txt"
#define CONFIG_FILE_VERSION "1.1"

#define DEBUG 0
#define DEBUG_BEAMRINGS 0

#define ORIGIN_TYPES_COUNT 5
#define MAX_ORIGINS_COUNT 20
#define MAX_ITEMS_COUNT 20
#define MAX_RINGS_COUNT 20

//orogin types
#define typeOriginRandom -1
#define typeOriginStart 0
#define typeOriginPreCenter 1
#define typeOriginCenter 2
#define typeOriginPreFinal 3
#define typeOriginFinal 4


//ammo in guns
#define AssaultMaxAmmo 360
#define SMGMaxAmmo 650
#define ShotgunMaxAmmo 56
#define AutoShotgunMaxAmmo 90
#define HRMaxAmmo 150
#define SniperRifleMaxAmmo 180
#define GrenadeLauncherMaxAmmo 30
#define M60MaxAmmo 150



// Models
new String:BeamSprite[] = "materials/sprites/laser.vmt";
new String:BeamSprite_[] = "materials/sprites/laser.vtf";
new String:HaloSprite[] = "materials/sprites/halo01.vmt";
new String:HaloSprite_[] = "materials/sprites/halo01.vtf";
new g_BeamSprite;
new g_HaloSprite;
new Handle:hCreateTimer;
new Handle:hCheckTimer;
new Handle:hAllowRings;
new Handle:hSpawnItemsTimer = INVALID_HANDLE;

new Handle:g_dpSpawnedItems;

new Handle:g_NoMoveDelay;
new Handle:g_FirstNoMoveDelay;

new Float:Rings[MAX_RINGS_COUNT][4];
new RingsCount;
new Float:fMaxDist;
new Float:fOnePercent;

static String:g_sOriginTypes[ORIGIN_TYPES_COUNT+1][13]  = {"Start","PreCenter", "Center", "PreFinal","Final","Advanced"};
new OriginsCount[ORIGIN_TYPES_COUNT];
new Float:Origins[ORIGIN_TYPES_COUNT][MAX_ORIGINS_COUNT][3];
new String:g_sItems[MAX_ITEMS_COUNT][32]; 
new ItemChances[MAX_ITEMS_COUNT];
new ItemChancesNoSF[MAX_ITEMS_COUNT];
new ItemFlags[MAX_ITEMS_COUNT];
new ItemsListCount=0
new ItemsMinCounts[ORIGIN_TYPES_COUNT+1];
new ItemsMaxCounts[ORIGIN_TYPES_COUNT+1];
new bool:bForceUnbalanced=false;
new bool:bFirstSpawn = true;
new bool:bMapItemsLoaded = false;

public Plugin:myinfo = 
{
	name = "[L4D2] Auto Spawn Items",
	author = "V10",
	description = "Automatic spawn items on configured origin positions",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=116376"
	
}

public OnPluginStart()
{
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	//cmds
	RegAdminCmd("sm_items_posinfo", Command_PosInfo, ADMFLAG_BAN,  "Prints position coords and angles");
	RegAdminCmd("sm_itemsmenu", Command_OriginsMenu, ADMFLAG_BAN,  "Auto spawn items menu");
	RegAdminCmd("sm_itemsstats", Command_ItemsStats, ADMFLAG_BAN);
	RegAdminCmd("sm_allitemsstats", Command_AllItemsStats, ADMFLAG_BAN);
	#if DEBUG
	RegAdminCmd("sm_spawnall", Command_SpawnAll, ADMFLAG_ROOT,  "Initiate spawn items");
	#endif
	
	//cvars
	hAllowRings = CreateConVar("sm_allowitemrings","0","Create Beam Rings on item spawn origins");
	g_NoMoveDelay = CreateConVar("sm_items_nomove_delay","1.5");
	g_FirstNoMoveDelay = CreateConVar("sm_items_first_nomove_delay","1.5");
	
	HookConVarChange(hAllowRings,AllowRingsChanged);
	
	CreateConVar("l4d2_autospawni_version", VERSION, "AutoSpawnItems plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_dpSpawnedItems = CreateDataPack();
}

// =======================================================================
// ============================  EVENTS ==================================
// =======================================================================

public Action:Timer_SpawnItems(Handle:timer)
{
	if (!bMapItemsLoaded) return Plugin_Continue;
	
	SpawnDefaultItems();
	SpawnSpecialItems();
	
	if (bFirstSpawn)
		CreateTimer(GetConVarFloat(g_FirstNoMoveDelay), Timer_SpawnComplete, _, TIMER_FLAG_NO_MAPCHANGE);
	else
		CreateTimer(GetConVarFloat(g_NoMoveDelay), Timer_SpawnComplete, _, TIMER_FLAG_NO_MAPCHANGE);
		
	bFirstSpawn = false;
	hSpawnItemsTimer = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:Event_RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	if (hSpawnItemsTimer != INVALID_HANDLE) return;
	ResetPack(g_dpSpawnedItems, true);
	#if DEBUG
	DebugPrint("Start Spawn items");
	#endif
	LoadItemsConfig();
	if (isConfigBalanced()){
		hSpawnItemsTimer = CreateTimer(1.0, Timer_SpawnItems, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	}else{
		PrintToServer("ERROR: Auto Spawn Items config not balanced, items not spawned! Please open config and balance. All items chances summ need to be 1000.");
	}
}



public OnMapStart()
{
	//add downloads
	AddFileToDownloadsTable(BeamSprite);
	AddFileToDownloadsTable(BeamSprite_);
	AddFileToDownloadsTable(HaloSprite);
	AddFileToDownloadsTable(HaloSprite_);
	//models
	g_BeamSprite=PrecacheModel(BeamSprite, false);
	g_HaloSprite=PrecacheModel(HaloSprite, false);		
	
	if (GetConVarBool(hAllowRings)){
		hCreateTimer=CreateTimer(1.0,CreateBeamRingTimer,_,TIMER_REPEAT+TIMER_FLAG_NO_MAPCHANGE);
		hCheckTimer=CreateTimer(5.0,CheckBeamRingsTimer,_,TIMER_REPEAT+TIMER_FLAG_NO_MAPCHANGE);
	}
	
	decl String:curMap[32];
	GetCurrentMap(curMap, sizeof(curMap));
	
	#if DEBUG
	DebugPrint("Map '%s' started!",curMap);
	#endif
	
	LoadItemsConfig();
	bMapItemsLoaded = true;
}

public OnMapEnd()
{
	bFirstSpawn	= true;
	bMapItemsLoaded = false;
	hSpawnItemsTimer = INVALID_HANDLE;
}

public AllowRingsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue)){
		if (!StringToInt(oldValue)){
			hCreateTimer=CreateTimer(1.0,CreateBeamRingTimer,_,TIMER_REPEAT+TIMER_FLAG_NO_MAPCHANGE);
			hCheckTimer=CreateTimer(5.0,CheckBeamRingsTimer,_,TIMER_REPEAT+TIMER_FLAG_NO_MAPCHANGE);
		}				
	}else{
		if (StringToInt(oldValue)){
			KillTimer(hCheckTimer);
			KillTimer(hCreateTimer);
		}		
	}
}

// =======================================================================
// ============================  COMMANDS ================================
// =======================================================================

#if DEBUG
public Action:Command_SpawnAll(client, args) {
	SpawnDefaultItems();
}
#endif

public Action:Command_PosInfo(client, args) {
	if (client==0) client=1;
	new Float:Origin[3];
	new Float:Angles[3];
	GetClientAbsOrigin(client,Origin);
	GetClientAbsAngles(client,Angles);
	ReplyToCommand(client,"Your origin: x=%f y=%f z=%f",Origin[0],Origin[1],Origin[2]);
	ReplyToCommand(client,"Your angles: x=%f y=%f z=%f",Angles[0],Angles[1],Angles[2]);
	
}

public Action:Command_OriginsMenu(client, args) {
	if (client==0) client=1;
	new Handle:menu = CreateMenu(OriginsMenuHandler);
	SetMenuTitle(menu, "Select Type:");
	AddMenuItem(menu, "option1", "Start");
	AddMenuItem(menu, "option2", "PreCenter");
	AddMenuItem(menu, "option3", "Center");
	AddMenuItem(menu, "option4", "PreFinal");
	AddMenuItem(menu, "option5", "Final");
	AddMenuItem(menu, "option6", "",ITEMDRAW_NOTEXT);
	AddMenuItem(menu, "option7", "Delete Current");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
	
}

// =======================================================================
// ============================  MENU HANDLERS ===========================
// =======================================================================

new tmpNewOriginType=0;
new tmpOrgNewOriginType=0;
new tmpNewPointExist=0;

public OriginsMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_Select){
		new Float:AddedOrigin[3];
		GetClientAbsOrigin(client,AddedOrigin);
		ReplyToCommand(client,"x=%f y=%f z=%f",AddedOrigin[0],AddedOrigin[1],AddedOrigin[2]);
		tmpNewOriginType=itemNum;
		tmpOrgNewOriginType=tmpNewOriginType;
		new Float:tmpOriginDist=500.0;
		tmpNewPointExist=isPointAlreadyAdded(AddedOrigin,tmpNewOriginType,tmpOriginDist);
		if (tmpNewPointExist==-1){
			if (itemNum==6){
				ReplyToCommand(client,"\x4Point not found around \x03500 radius.");				
				return;
			}
			AddNewOriginsPoint(client,tmpNewOriginType,AddedOrigin);
		}else{
			if (itemNum==6){
				new Handle:menunew = CreateMenu(DeleteConfirmHandler);
				SetMenuTitle(menunew, "Confirm delete %s[%d], dist=%f:",g_sOriginTypes[tmpNewOriginType],tmpNewPointExist,tmpOriginDist);
				AddMenuItem(menunew, "option1", "No");
				AddMenuItem(menunew, "option2", "Yes");
				DisplayMenu(menunew, client, MENU_TIME_FOREVER);
				return;
			}
			new Handle:menunew = CreateMenu(OriginsConfirmHandler);
			SetMenuTitle(menunew, "Origin exist on %s[%d], dist=%f:",g_sOriginTypes[tmpNewOriginType],tmpNewPointExist,tmpOriginDist);
			AddMenuItem(menunew, "option1", "Ignore");
			AddMenuItem(menunew, "option2", "Replace");
			SetMenuExitButton(menunew, true);
			DisplayMenu(menunew, client, MENU_TIME_FOREVER);
			
		}
	}
}

public DeleteConfirmHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_Select && itemNum==1)
		DeleteOriginsPoint(tmpNewOriginType,tmpNewPointExist,client);
}
public OriginsConfirmHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_Select){
		new Float:AddedOrigin[3];
		GetClientAbsOrigin(client,AddedOrigin);
		if (itemNum==0)
			AddNewOriginsPoint(client,tmpOrgNewOriginType,AddedOrigin);  	
		else if(itemNum==1)
			AddNewOriginsPoint(client,tmpNewOriginType,AddedOrigin,true,tmpNewPointExist);  	  	  
	}
}

// =======================================================================
// ================================  CONFIG ==============================
// =======================================================================

Handle:OpenItemsConfig(const String:map[]="",OriginType=-1,bool:nomap=false, String:ConfigType[]="Maps")
{
	static String:sPath[256];
	new String:Map[32];
	
	if (sPath[0]==0) BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_FILE);
	if (!nomap && map[0]==0) GetCurrentMap(Map, 32);
	else strcopy(Map,32,map);
	
	//Load
	new Handle:kv = CreateKeyValues("AutoSpawnConfig");
	FileToKeyValues(kv,sPath);
	if (!KvJumpToKey(kv,ConfigType)){
		SetFailState("Cant find %s config section",ConfigType);
		return INVALID_HANDLE;
	}
	if (!nomap) KvJumpToKey(kv,Map,true);
	if (!nomap && OriginType!=-1) KvJumpToKey(kv,g_sOriginTypes[OriginType],true);
	return kv;
}

CloseItemsConfig(Handle:kv, save=false)
{
	if (save){
		static String:sPath[256];
		if (sPath[0]==0) BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_FILE);
		//Save
		KvRewind(kv);
		KeyValuesToFile(kv,sPath);
	}
	CloseHandle(kv);
}

isConfigBalanced()
{
	//	return !bForceUnbalanced;
	return true;
}

LoadItemsConfig(){
	new Handle:kv = OpenItemsConfig(_,_,true,"Options");
	bForceUnbalanced=false;
	
	//Parse Chances
	new total=0;
	if (KvJumpToKey(kv,"Items",false) && KvJumpToKey(kv,"Chances",false)){
		new counter = 0;
		KvGotoFirstSubKey(kv,false);
		do{
			decl String:Value[10];
			decl String:Values[2][10];
			KvGetSectionName(kv,g_sItems[counter],32);
			KvGetString(kv,"",Value,sizeof(Value));
			new ParamCount=ExplodeString(Value,";",Values,2,sizeof(Value));
			ItemChances[counter]=StringToInt(Values[0]);
			total+=ItemChances[counter];
			if (ParamCount>1) ItemFlags[counter]=StringToInt(Values[1]);			
			counter++;
		}while(KvGotoNextKey(kv,false));
		ItemsListCount=counter;
		if (total!=1000) bForceUnbalanced=true;
	}else SetFailState("Not found needed section in config file.");
	
	// recalc no start\final
	//Calc Free
	new iFree=0;
	new GoodCount=0;
	for (new i = 0; i < ItemsListCount; i++){
		if (ItemFlags[i]) iFree+=ItemChances[i];
		else{
			GoodCount++;
			ItemChancesNoSF[i]=ItemChances[i];
		}
	}
	//Recalc local table
	if (iFree!=0){
		new byOne=iFree/GoodCount;
		for (new i = 0; i < ItemsListCount; i++){if (!ItemFlags[i]) ItemChancesNoSF[i]+=byOne;}	
	}	
	
	if (bForceUnbalanced) PrintToServer("Items unbalanced. 1000!=%d",total);
	
	//return to Items
	KvGoBack(kv);KvGoBack(kv);
	//parse global counts
	if (!ParseCounts(kv)) SetFailState("Not found Counts section in config file.");
	//close file
	CloseItemsConfig(kv);
	
	//Parse map origins and counts
	kv=OpenItemsConfig();
	for (new i = typeOriginStart; i <= typeOriginFinal; i++) 
		OriginsCount[i]=FillOrigins(kv,i,Origins[i]);
	ParseCounts(kv);
	CloseItemsConfig(kv);
	
	fMaxDist=GetVectorDistance(Origins[typeOriginStart][0],Origins[typeOriginFinal][0]);
	fOnePercent=FloatDiv(FloatAbs(fMaxDist),100.0);
	
	#if DEBUG
	DebugPrint("Loaded origins: SO:%d, PCO:%d, CO:%d, PFO:%d, FO:%d",OriginsCount[typeOriginStart],OriginsCount[typeOriginPreCenter],OriginsCount[typeOriginCenter],OriginsCount[typeOriginPreFinal],OriginsCount[typeOriginFinal]);
	DebugPrint("Loaded items:");
	for (new i = 0; i < ItemsListCount; i++)
		DebugPrint("Name=%s, Chance=%d, Flag=%d, ChanseNoSF=%d",g_sItems[i],ItemChances[i],ItemFlags[i],ItemChancesNoSF[i]);
	
	DebugPrint("Loaded counts:");
	for (new i = 0; i <= ORIGIN_TYPES_COUNT; i++)
		DebugPrint("Origin=%s, MinCount=%d, MaxCount=%d",g_sOriginTypes[i],ItemsMinCounts[i],ItemsMaxCounts[i]);			
	#endif
}

ParseCounts(Handle:kv){
	if (KvJumpToKey(kv,"Counts",false)){
		for (new i = 0; i <= ORIGIN_TYPES_COUNT; i++){
			decl String:Value[10];
			decl String:Values[2][10];
			KvGetString(kv,g_sOriginTypes[i],Value,sizeof(Value));
			if (!Value[0]) continue;
			ExplodeString(Value,";",Values,2,sizeof(Value));
			ItemsMinCounts[i]=StringToInt(Values[0]);
			ItemsMaxCounts[i]=StringToInt(Values[1]);			
			//	PrintToServer("Name=%s, min=%d, max=%d",g_sOriginTypes[i],ItemsMinCounts[i],ItemsMaxCounts[i]);			
		}
		return true;
	}
	return false;
}

// =======================================================================
// ================================  ORIGINS =============================
// =======================================================================

stock FillOrigins(Handle:kv,typeid,Float:array[MAX_ORIGINS_COUNT][3]){
	new String:ValName[5];
	new Float:origin[3];
	new count=0;
	KvSavePosition(kv);
	if (KvJumpToKey(kv,g_sOriginTypes[typeid])){
		for (new z = 0; z < MAX_ORIGINS_COUNT; z++){
			IntToString(z,ValName,sizeof(ValName));
			KvGetVector(kv,ValName,origin);
			if (origin[0]==0 && origin[1]==0 && origin[2]==0) break;
			array[z]=origin;
			count++;
		}
	}else{		
		for (new z = 0; z < MAX_ORIGINS_COUNT; z++)	{
			array[z][0]=0.0;
			array[z][1]=0.0;
			array[z][2]=0.0;
		}
		#if DEBUG
		decl String:tmpName[50];
		KvGetSectionName(kv,tmpName,sizeof(tmpName));
		DebugPrint("Cant find %s key in %s",g_sOriginTypes[typeid],tmpName);
		#endif		
	}
	KvGoBack(kv);
	return count;
}

stock isPointAlreadyAdded(const Float:current[3],&type,&Float:dist){
	new LastFoundIndex=-1;
	for (new i = typeOriginStart; i <= typeOriginFinal; i++){
		for (new n = 0; n < OriginsCount[i]; n++){
			new Float:tmpdist=GetVectorDistance(Origins[i][n],current);
			if (tmpdist<dist){
				dist=tmpdist;
				type=i;
				LastFoundIndex=n;
			}
		}
	}
	return LastFoundIndex;
}

AddNewOriginsPoint(client,type,Float:Origin[3],replace=false,id=0){
	new String:ValName[5];
	//Load
	new Handle:kv = OpenItemsConfig(_,type);
	new NextNum=id;
	if (!replace){
		//add
		NextNum=GetNextOriginNum(kv);
		IntToString(NextNum,ValName,sizeof(ValName));
		new originsc=OriginsCount[type];
		Origins[type][originsc]=Origin;
		OriginsCount[type]=NextNum+1;
	}else{
		IntToString(id,ValName,sizeof(ValName));
		Origins[type][id]=Origin;
	}
	KvSetVector(kv,ValName,Origin);
	//reply
	if (client){
		ReplyToCommand(client,"\x4Success saved \x3%s \x4point as num \x3%d",g_sOriginTypes[type],NextNum);
	}
	
	//Save
	CloseItemsConfig(kv,true);
}

DeleteOriginsPoint(type,id,client=0){
	new String:ValName[5];
	//Load
	new Handle:kv = OpenItemsConfig(_,type);
	new LastNum=OriginsCount[type]-1; //GetNextOriginNum(kv);
	if (id!=LastNum){
		IntToString(id,ValName,sizeof(ValName));
		Origins[type][id]=Origins[type][LastNum];
		KvSetVector(kv,ValName,Origins[type][LastNum]);
	}
	IntToString(LastNum,ValName,sizeof(ValName));
	KvDeleteKey(kv,ValName);
	OriginsCount[type]--;
	//reply
	if (client){
		ReplyToCommand(client,"\x4Success deleted \x3%s \x4point num \x3%d",g_sOriginTypes[type],id);
	}
	#if DEBUG
	DebugPrint("Deleted %s origin, num=%d",g_sOriginTypes[type],id);
	#endif
	
	//Save
	CloseItemsConfig(kv,true);
}


stock GetNextOriginNum(Handle:kv){
	new count=0;
	//	KvSavePosition(kv);
	if (KvJumpToKey(kv,"0")){
		new String:tmpStr[100];
		do
		{
			KvGetSectionName(kv,tmpStr,sizeof(tmpStr))
			if (StrContains(tmpStr,"SpecialItems")==-1)
				count++;
		} while (KvGotoNextKey(kv,false));
		KvGoBack(kv);
	}
	return count;	
}

stock Float:GetRandomOrigin(type=-1){	
	if (type==-1)
		type=GetRandomInt(typeOriginStart,typeOriginFinal);
	new Float:Origin[3];
	new rnd1;
	if (OriginsCount[type]==0) return Origin;
	if (OriginsCount[type]==1) return Origins[type][0];
	rnd1= GetRandomInt(0,OriginsCount[type]-1);
	Origin=Origins[type][rnd1];
	#if DEBUG
	DebugPrint("Generated random origin %f %f %f, type=%d, num=%d",Origin[0],Origin[1],Origin[2],type,rnd1);
	#endif
	return Origin;
}

// =======================================================================
// ============================  SPAWN ITEMS =============================
// =======================================================================

SpawnDefaultItems()
{
	
	SpawnItemsTypeCountR(typeOriginRandom,ItemsMinCounts[ORIGIN_TYPES_COUNT],ItemsMaxCounts[ORIGIN_TYPES_COUNT]);
	for (new i = typeOriginStart; i <= typeOriginFinal; i++)
		SpawnItemsTypeCountR(i,ItemsMinCounts[i],ItemsMaxCounts[i]);
	
}

SpawnSpecialItems(){
	new Handle:kv = OpenItemsConfig(_,_,true);
	new String:Map[32];
	GetCurrentMap(Map, 32);
	SubSpawnSpecialItems(kv,Map);
	SubSpawnSpecialItems(kv,"All");
	CloseItemsConfig(kv,false);
}

SubSpawnSpecialItems(Handle:kv,const String:Map[]){
	if (KvJumpToKey(kv,Map)){
		for (new i = typeOriginStart; i <= typeOriginFinal; i++){
			if (KvJumpToKey(kv,g_sOriginTypes[i])){
				if (KvJumpToKey(kv,"SpecialItems")){
					KvGotoFirstSubKey(kv,false);
					do{
						decl String:Item[50];
						KvGetSectionName(kv,Item,sizeof(Item));
						new count=KvGetNum(kv,"");
						#if DEBUG
						DebugPrint("Parse specitem '%s' count=%s",Item,count);
						#endif
						if (count>1) SpawnItemsCountR(Item,count,i);
						else  SpawnItemRandomle(Item,GetRandomOrigin(i));											
					}while(KvGotoNextKey(kv,false));
					KvGoBack(kv);
					KvGoBack(kv);
				}		
				KvGoBack(kv);
			}
		}
		KvGoBack(kv);
	} 
}

public Action:Timer_SpawnComplete(Handle:timer)
{
	ResetPack(g_dpSpawnedItems);
	new index;
	while (IsPackReadable(g_dpSpawnedItems, 4)){
		index = ReadPackCell(g_dpSpawnedItems);
		if (IsValidEntity(index))
			SetEntityMoveType(index, MOVETYPE_NONE);	
	}
}

// =======================================================================
// ============================  SPAWN FUNCS =============================
// =======================================================================

SpawnItemsCountR(const String:Item[],count,type)
{
	for (new z = 1; z <= count; z++)
		SpawnItemRandomle(Item,GetRandomOrigin(type));
}

SpawnItemsTypeCountR(type,min,max)
{
	new Count;
	if (type==typeOriginRandom) type=GetRandomInt(typeOriginPreCenter,typeOriginPreFinal);		
	if (min==max) Count=min;
	else Count=GetRandomInt(min,max);
	
	for (new z = 1; z <= Count; z++)
		SpawnRandomItem(GetRandomOrigin(type),type);
}

SpawnItem(const String:Item[],const Float:Where[3]){
	if (Where[0]!=0){
		//for weapon
		new maxammo;
		if (StrEqual(Item, "weapon_rifle", false) || StrEqual(Item, "weapon_rifle_ak47", false) || StrEqual(Item, "weapon_rifle_desert", false) || StrEqual(Item, "weapon_rifle_sg552", false)){
			maxammo = AssaultMaxAmmo;
		}else if (StrEqual(Item, "weapon_smg", false) || StrEqual(Item, "weapon_smg_silenced", false) || StrEqual(Item, "weapon_smg_mp5", false)){
			maxammo = SMGMaxAmmo;
		}else if (StrEqual(Item, "weapon_pumpshotgun", false) || StrEqual(Item, "weapon_shotgun_chrome", false)){
			maxammo = ShotgunMaxAmmo;
		}else if (StrEqual(Item, "weapon_autoshotgun", false) || StrEqual(Item, "weapon_shotgun_spas", false)){
			maxammo = AutoShotgunMaxAmmo;
		}else if (StrEqual(Item, "weapon_hunting_rifle", false)){
			maxammo = HRMaxAmmo;
		}else if (StrEqual(Item, "weapon_sniper_military", false) || StrEqual(Item, "weapon_sniper_awp", false) || StrEqual(Item, "weapon_sniper_scout", false)){
			maxammo = SniperRifleMaxAmmo;
		}else if (StrEqual(Item, "weapon_grenade_launcher", false)){
			maxammo = GrenadeLauncherMaxAmmo;
		}else if (StrEqual(Item, "weapon_rifle_m60", false)){
			maxammo = M60MaxAmmo;
		}
		new index = CreateEntityByName(Item);
		if (index!=-1){
			TeleportEntity(index, Where, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(index);
			if (maxammo){
				SetEntProp(index, Prop_Send, "m_iExtraPrimaryAmmo", maxammo ,4);
			}
			ActivateEntity(index);
			WritePackCell(g_dpSpawnedItems, index);
			
			#if DEBUG
			DebugPrint("Spawn item '%s' at %f %f %f",Item,Where[0],Where[1],Where[2]);
			#endif
		}else{
			#if DEBUG
			DebugPrint("ERROR on spawn item '%s' at %f %f %f",Item,Where[0],Where[1],Where[2]);			
			#endif
		}
	}else{
		#if DEBUG
		DebugPrint("ERROR spawn item coords is NULL '%s'",Item);
		#endif
	}
}

SpawnItemRandomle(const String:Item[],Float:Where[3]){
	if (Where[0]==0.0 && Where[1]==0.0 && Where[2]==0.0) return 
	Where[0]=Where[0]+(GetRandomInt(0,100)-50);
	Where[1]=Where[1]+(GetRandomInt(0,100)-50);
	Where[2]=Where[2]+30.0;
	SpawnItem(Item,Where);
}


SpawnRandomItem(Float:where[3],typeOrigin=typeOriginRandom){
	new total=0;
	new Chances[MAX_ITEMS_COUNT];
	
	if (typeOrigin==typeOriginStart || typeOrigin==typeOriginFinal) Chances=ItemChancesNoSF;
	else Chances=ItemChances;
	
	new item=GetRandomInt(1,1000);	
	for (new i = 0; i < MAX_ITEMS_COUNT; i++){
		if (item>=total && item<total+Chances[i]){
			#if DEBUG
			DebugPrint("Generated random item: %s, chance=%d, curchance=%d, rnd=%d",g_sItems[i],Chances[i],total,item);
			#endif
			SpawnItemRandomle(g_sItems[i],where);
			return;
		}
		total=total+Chances[i];
	}
}

// =======================================================================
// ============================  POINTS STATS ============================
// =======================================================================

public Action:Command_ItemsStats(client, args) {
	ReplyToCommand(client,"\x4Stats:");
	new fAllOK=true;
	if ( OriginsCount[typeOriginStart]<2){
		ReplyToCommand(client,"\x3- No Start origin");
		fAllOK=false;
	}
	if ( OriginsCount[typeOriginFinal]<1){
		ReplyToCommand(client,"\x3- No Final origin");
		fAllOK=false;
	}
	if ( OriginsCount[typeOriginPreCenter]<5){
		ReplyToCommand(client,"\x3- Need more PreCenter origins, now:\x4%d",OriginsCount[typeOriginPreCenter]);
		fAllOK=false;
	}
	if ( OriginsCount[typeOriginCenter]<5){
		ReplyToCommand(client,"\x3- Need more Center origins, now:\x4%d",OriginsCount[typeOriginCenter]);
		fAllOK=false;
	}
	if ( OriginsCount[typeOriginPreFinal]<5){
		ReplyToCommand(client,"\x3- Need more PreFinal origins, now:\x4%d",OriginsCount[typeOriginPreFinal]);
		fAllOK=false;
	}
	if (fAllOK){
		ReplyToCommand(client,"\x3- Map Origins Complete");
	}
	PrintToConsole(client,"Loaded origins: SO:%d, PCO:%d, CO:%d, PFO:%d, FO:%d",OriginsCount[typeOriginStart],OriginsCount[typeOriginPreCenter],OriginsCount[typeOriginCenter],OriginsCount[typeOriginPreFinal],OriginsCount[typeOriginFinal]);
	return Plugin_Handled;
}

public Action:Command_AllItemsStats(client, args) {
	new Handle:kv = OpenItemsConfig(_,_,true);
	
	//maps
	KvGotoFirstSubKey(kv);
	do
	{
		new fAllOK=true;
		new fMapSended=false;
		new String:MapName[100];
		KvGetSectionName(kv,MapName,sizeof(MapName))
		if (!strcmp(MapName,"All"))
			continue;
		KvSavePosition(kv);
		for (new z = 0; z < 5; z++){
			new count=0;
			if(KvJumpToKey(kv,g_sOriginTypes[z])){
				count=GetNextOriginNum(kv);
				KvGoBack(kv);
			}			
			if (z==0 && count<2){
				if (!fMapSended){
					ReplyToCommand(client,"\x4Map: \x3%s",MapName);
					fMapSended=true;
				}
				ReplyToCommand(client,"\x3- No Start origin");
				fAllOK=false;
			}
			if (z==4 && count<1){
				if (!fMapSended){
					ReplyToCommand(client,"\x4Map: \x3%s",MapName);
					fMapSended=true;
				}
				ReplyToCommand(client,"\x3- No Final origin");
				fAllOK=false;
			}
			if (z==1 && count<5){
				if (!fMapSended){
					ReplyToCommand(client,"\x4Map: \x3%s",MapName);
					fMapSended=true;
				}
				ReplyToCommand(client,"\x3- Need more PreCenter origins, now:\x4%d",count);
				fAllOK=false;
			}
			if (z==2 && count<5){
				if (!fMapSended){
					ReplyToCommand(client,"\x4Map: \x3%s",MapName);
					fMapSended=true;
				}
				ReplyToCommand(client,"\x3- Need more Center origins, now:\x4%d",count);
				fAllOK=false;
			}
			if (z==3 && count<5){
				if (!fMapSended){
					ReplyToCommand(client,"\x4Map: \x3%s",MapName);
					fMapSended=true;
				}
				ReplyToCommand(client,"\x3- Need more PreFinal origins, now:\x4%d",count);
				fAllOK=false;
			}			
		}
		if (!fAllOK){
			ReplyToCommand(client,"\x4=================================");		
		}
		KvGoBack(kv);
	} while (KvGotoNextKey(kv,false));
	CloseItemsConfig(kv);
	return Plugin_Handled;
}

// =======================================================================
// ============================  BEAM RING ===============================
// =======================================================================

stock isPointAroundPlayer(const Float:current[3],Float:CheckMaxDist=1100.0){
	decl Float:AbsOrigin[3];
	for (new i=1; i<=MaxClients; i++){ 
		if (!IsClientInGame(i)) continue; //not ingame? skip
		if (IsFakeClient(i)) continue; //bot? skip
		if (GetClientTeam(i) == 3) continue; //not survivor? skip
		if ((GetClientTeam(i) == 1 || !IsPlayerAlive(i)) && !(GetUserFlagBits(i) &(ADMFLAG_GENERIC | ADMFLAG_ROOT))) continue

		
		GetClientAbsOrigin(i,AbsOrigin);
		if (GetVectorDistance(AbsOrigin,current)<CheckMaxDist) return i;
	}
	return -1;
}

public Action:CheckBeamRingsTimer(Handle:timer)
{
	RingsCount=0;
	for (new i = typeOriginStart; i <= typeOriginFinal; i++){
		for (new n = 0; n < OriginsCount[i]; n++){
			if (isPointAroundPlayer(Origins[i][n])==-1) continue;
			AddBeamRing(Origins[i][n]);
		}
	}
	
	return Plugin_Continue;
}

public Action:CreateBeamRingTimer(Handle:timer)
{
	static bool:bIn=false;
	if (!RingsCount) return Plugin_Continue;
	for (new i = 0; i < RingsCount; i++){
		new Float:where[3];
		where[0]=Rings[i][0];
		where[1]=Rings[i][1];
		where[2]=Rings[i][2];
		CreateBeamRing(where,bIn,Rings[i][3]);
	}
	bIn=!bIn;
	return Plugin_Continue;
}

CreateBeamRing(Float:where[3],bool:bIn=false, Float:minRadius){
	new Float:fCurDist=fMaxDist-GetVectorDistance(Origins[typeOriginFinal][0],where);
	new Float:fCurPercent=FloatDiv(FloatAbs(fCurDist),fOnePercent);
	new RingColor[4] = {255, 0, 0, 50};
	if (FloatCompare(fCurPercent,50.0)<=0){
		if (FloatCompare(fCurPercent,30.0)>0)
			RingColor[1]=255;
//		RingColor[1]=FloatMul(FloatMul(fCurPercent,2.0),2.55);
	}else{
		RingColor[1]=255;
		if (FloatCompare(fCurPercent,60.0)>0)
			RingColor[0]=0;
//		RingColor[0]=255-RoundToFloor(FloatMul(FloatMul(FloatSub(fCurPercent,50.0),2.0),2.55));
	}
	
	TE_SetupBeamRingPoint(where,(bIn?minRadius*2:minRadius), (bIn?minRadius:minRadius*2), g_BeamSprite, g_HaloSprite, 0, 1, 1.0, 3.0, 0.0, RingColor, 1, 0);
	TE_SendToAllSurvivors();	
}

stock TE_SendToAllSurvivors(Float:delay=0.0)
{
	new maxClients = GetMaxClients();
	new total = 0;
	new clients[maxClients];
	for (new i=1; i<=maxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) != 3)
		{
			clients[total++] = i;
		}
	}
	return TE_Send(clients, total, delay);
}

AddBeamRing(Float:where[3],Float:minRadius=100.0){
	if (RingsCount>=MAX_RINGS_COUNT) return;
	Rings[RingsCount][0]=where[0];
	Rings[RingsCount][1]=where[1];
	Rings[RingsCount][2]=where[2];
	Rings[RingsCount][3]=minRadius;
	RingsCount++;
	#if DEBUG_BEAMRINGS
	DebugPrint("Added BeamRing [ %f, %f, %f ], count=%d",where[0],where[1],where[2],RingsCount);
	#endif
}

stock DeleteBeamRing(Float:where[3]){
	#if DEBUG_BEAMRINGS
	DebugPrint("Deleted BeamRing [ %f, %f, %f ]",where[0],where[1]where[2]);
	#endif
	for (new i = 0; i < RingsCount; i++){
		if (Rings[i][0]==where[0] && Rings[i][1]==where[1] && Rings[i][2]==where[2]){
			if (i==RingsCount-1){
				RingsCount--;
				return;
			}
			Rings[i][0]=Rings[RingsCount-1][0];
			Rings[i][1]=Rings[RingsCount-1][1];
			Rings[i][2]=Rings[RingsCount-1][2];
			Rings[i][3]=Rings[RingsCount-1][3];
			RingsCount--;
			return;
		}
	}
}

// =======================================================================
// ============================  STUFF ===================================
// =======================================================================

stock GetInGameClient()
{
	for( new x = 1; x <= GetClientCount( true ); x++ )
	{
		if( IsClientInGame( x ) && GetClientTeam( x ) == 2 )
		{
			return x;
		}
	}
	return 0;
}


#if DEBUG
DebugPrint(const String:format[], any:...)
{
	static bool:bLogFileInit=false;
	static String:logPath[256];
	decl String:buffer[300];
	VFormat(buffer, sizeof(buffer), format, 2);
	if (!bLogFileInit){
		BuildPath(Path_SM, logPath, sizeof(logPath), "logs/AutoSpawnItems.log");	
		bLogFileInit=true;
	}
	//PrintToChatAll(buffer);
	LogToFileEx(logPath,buffer);
}
#endif
