//我学习了enum sturct 与 arraylist的概念，然后为了融会贯通我所学的，所以做了这个老虎机项目

//图案  序号 数量 奖励  数量	奖励
// 🍒 → 0   {2:	10,		3:	  50}	0.5/16
// 🍏 → 1	{2:	20,		3: 	  60}	0.5/16 + 1/16
// 🍋 → 2   {2:	30,		3: 	  70}	0.5/16 + 1/16*2
// 🍊 → 3   {2:	40,		3: 	  80}
// 🍇 → 4   {2:	50,		3: 	  90}
// ⭐ → 5   {2: 60,	   3:	100}
// 💎 → 6   {2:	70,		3:	 110}
// 	7 → 7   {2:	100,	3:	  200}

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define DEBUG 0

#define ACT_SELECT_LAST 0	//编辑功能-选择上一个
#define ACT_SELECT_NEXT 1	//编辑功能-选择下一个

#define ACT_MOVE 0		//放置功能-移动
#define ACT_ROTATE 1	//放置功能-旋转
//position｛X,Y,Z｝
#define ACT_X_MOVE 0	//移动功能-X轴
#define ACT_Y_MOVE 1	//移动功能-Y轴
#define ACT_Z_MOVE 2	//移动功能-Z轴
//angle｛Y,Z,X｝
#define ACT_X_ROTATE 2	//旋转功能-X轴
#define ACT_Y_ROTATE 0	//旋转功能-Y轴
#define ACT_Z_ROTATE 1	//旋转功能-Z轴

#define MAX_MACHINE 30	//最多放几台机器
#define ICONS_COUNT 8	//图标种类数
#define NORMAL_COST 1	//每次下注消耗
#define WHEEL_COUNT 3	//轮子数量
// #define WHEEL_ICONS 16	//轮子面数

static char s_models[][] = {
	"models/smachine/sm01.mdl",
	"models/smachine/sm02.mdl",
	"models/props/cs_militia/silo_01.mdl"
};

static char s_sounds[][] = {
	"ui/buttonclickrelease.wav",	//0 点击停止 ui/beep07.wav "level/pointscored.wav",// "level/timer_bell.wav.wav",
	"level/highscore.wav",		//1 3连
	"level/loud/climber.wav",	//2 2连 && 3连
	"ui/beep_error01.wav",		//3 非酋	"level/puck_fail.wav",
	"rockBody.mp3",				//4 进行时
	"ui/pickup_secret01.wav"	//5 脱离机器
}

char w_Icons[][][] = {//字典
	{"樱桃",	"1",	"5",	"cherry"},
	{"苹果",	"2",	"6",	"green-apple"},
	{"柠檬",	"3",	"7",	"lemon"},
	{"橘子",	"4",	"8",	"orange"},
	{"葡萄",	"5",	"9",	"grape"},
	{"星星",	"6",	"10",	"star"},
	{"钻石",	"10",	"20",	"diamond"},
	{"幸运7",	"15",	"30",	"7"}
};

// int p_credits = 1000;
int s_Count;	//生成数量统计
int s_Select;	//当前编辑对象

//有人提出methodmap更接近面向对象编程的概念，或许这次我使用enum struct又是走进了歧路（悲）
enum struct SlotMachine {
	int Body;				//机器本体
	int Button;				//激活按钮
	int Trigger;			//人员触发范围判定
	int w_Index;			//轮子-左
	int w_Index2;			//轮子-中
	int w_Index3;			//轮子-右

	int w_Owner;			//当前机器使用者
	int w_LastOwner;		//机器最后的使用者
	int w_stopCount;		//停止了几个轮子
	// int w_cost;			//投币数 倍率功能暂时随着菜单一起被弃用
	int w_result[3];		//老虎机结果
	bool isRotate;			//是否在转
}
//场上老虎机对象数组
ArrayList machineList;

public Plugin myinfo = {
	name = 			"老虎机-公开版",
	author =		"CD意识STEAM_1:0:211123334 (Alliedmods:kazya3)",
	description = 	"老虎机,公开版，赌钱修改为赌命",
	version =		"1.2.1",
	url = ""
}

public void OnPluginStart(){
	//初始化arraylist
	machineList = new ArrayList(sizeof(SlotMachine));
	//如果没有对应目录，创建目录
	BuildFileDirectories();
	// RegConsoleCmd("sm_s",	menu);
	RegAdminCmd("sm_sm",    SMachineMenu,    ADMFLAG_ROOT, 	"老虎机生成菜单 spawn machine menu");
	// RegAdminCmd("sm_p",    test,    		ADMFLAG_ROOT, 	"在准星处生成老虎机 spawn machine at the crosshair");
	// RegAdminCmd("sm_s",    PropSave,    	ADMFLAG_ROOT, 	"保存场上老虎机位置 save all machines's position");
	// RegAdminCmd("sm_d",    PropDelete,   	ADMFLAG_ROOT, 	"删除场上所有老虎机 delete all machines");
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public void OnPluginEnd(){
 delete machineList;
}

public Action SMachineMenu(int client, int args){
	if( !client ) return Plugin_Handled;
	ShowMainMenu(client);
	return Plugin_Handled;
}

public Action test(int client, int args){
	if( !client ) return Plugin_Handled;
	SpawnMachineAtCrosshair(client);
	return Plugin_Handled;
}

public Action PropSave(int client, int args){
	if(!client) return Plugin_Handled;
	SaveMachine();
	return Plugin_Handled;
}

public Action PropDelete(int client, int args){
	if(!client) return Plugin_Handled;
	DeleteAll(client);
	return Plugin_Handled;
}
/* 
==============================================

 // MARK: - Precache

==============================================
 */
public void OnMapStart(){
	for ( int i = 0; i < sizeof(s_models); i++ ){
		PrecacheModel(s_models[i]);
	}
	for ( int i = 0; i < sizeof(s_sounds); i++ ){
		PrecacheSound(s_sounds[i], true);
	}
}
/* 
==============================================

 // MARK: - Placement Menu 

==============================================
 */
 //////////////////主菜单//////////////////
void ShowMainMenu(int client){
	//主菜单
	Menu g_hMenuMain = new Menu(MainMenuHandler);
	// g_hMenuMain.SetTitle("老虎机\n══════════════\n▶ 总数量: %d \n══════════════", s_Count);
	g_hMenuMain.SetTitle("══════════════\n▶ 老虎机\n══════════════");
	g_hMenuMain.AddItem("","准星处生成");
	g_hMenuMain.AddItem("","编辑");
	g_hMenuMain.AddItem("","保存");
	g_hMenuMain.AddItem("","重载");
	g_hMenuMain.AddItem("","删除所有");
	g_hMenuMain.ExitButton = true;	
	g_hMenuMain.Display(client, MENU_TIME_FOREVER);
	//取消所有高亮
	MakeGlow(s_Select, false);
}
public int MainMenuHandler(Menu menu, MenuAction action, int client, int index){
	if (action == MenuAction_Select){
		switch( index ){
			case 0:	{
				SpawnMachineAtCrosshair(client);
				ShowMainMenu(client);
			}
			case 1:	ShowEditMenu(client);
			case 2:	{
				SaveMachine();
				ShowMainMenu(client);
			}
			case 3:	{
				Reload(client);
				ShowMainMenu(client);
			}
			case 4:	{
				DeleteAll(client);
				ShowMainMenu(client);
			}
		}
	}
	if (action == MenuAction_End) delete menu;
	return 0;
}

//////////////////编辑调整菜单//////////////////
void ShowEditMenu(int client){
	char line[512];
	FormatEx(line, 512, "老虎机\n══════════════\n▶ 总数量: %d \n▶ 编辑对象: %d 号\n══════════════", s_Count, s_Select);
	//菜单生成
	Panel EditMenu = new Panel();
	SetPanelTitle(EditMenu, line);
	DrawPanelItem(EditMenu, "上一个");//1
	DrawPanelItem(EditMenu, "下一个");//2
	DrawPanelItem(EditMenu, "移动");//3
	DrawPanelItem(EditMenu, "旋转");//4
	DrawPanelItem(EditMenu, "删除编辑对象");//5
	DrawPanelItem(EditMenu, "返回", ITEMDRAW_DISABLED);//6
	SendPanelToClient(EditMenu, client, EditMenuFunc, MENU_TIME_FOREVER);
	delete EditMenu;
	//让编辑对象高亮
	MakeGlow(s_Select);
}
public int EditMenuFunc(Handle menu, MenuAction action, int client, int param2){
	if (action == MenuAction_Select){
		switch(param2){
			case 1:	{
				SelectToggle(ACT_SELECT_LAST);
				ShowEditMenu(client);
			}
			case 2:	{
				SelectToggle(ACT_SELECT_NEXT);
				ShowEditMenu(client);
			}
			case 3:	ShowAxisMenu(client, ACT_MOVE);
			// case 4:	ShowAxisMenu(client, ACT_ROTATE);
			case 4:	ShowActionDetailMenu(client, ACT_Z_ROTATE, ACT_ROTATE);
			case 5:	{
				DeleteLast();
				ShowEditMenu(client);
			}
			default:ShowMainMenu(client);
		}
	}
	return 0;
}

//////////////////选择移动轴的菜单//////////////////
void ShowAxisMenu(int client,int action){
	if(s_Select < 1) {
		ShowEditMenu(client);
		return;
	}
	char line[512];
	FormatEx(line, 512, "老虎机\n══════════════\n▶ 模式: %s \n▶ 编辑对象: %d 号\n══════════════", action == 0 ? "移动" : "旋转", s_Select);
	//菜单生成
	Panel AxisMenu = new Panel();
	SetPanelTitle(AxisMenu, line);
	//旋转只允许Z轴（这个功能浪费了我太多时间，所以我阉了其他轴）
	if(action == ACT_MOVE){
		DrawPanelItem(AxisMenu, "X轴");
		DrawPanelItem(AxisMenu, "Y轴");
	}
	DrawPanelItem(AxisMenu, "Z轴");
	DrawPanelItem(AxisMenu, "返回", ITEMDRAW_DISABLED);//4
	if(action == ACT_MOVE) SendPanelToClient(AxisMenu, client, AxisMenuFunc, MENU_TIME_FOREVER);
	else SendPanelToClient(AxisMenu, client, Axis2MenuFunc, MENU_TIME_FOREVER);
	delete AxisMenu;
}
public int AxisMenuFunc(Handle menu, MenuAction action, int client, int param2){
	if (action == MenuAction_Select){
		switch(param2){
			case 1:	ShowActionDetailMenu(client, ACT_X_MOVE, ACT_MOVE);
			case 2:	ShowActionDetailMenu(client, ACT_Y_MOVE, ACT_MOVE);
			case 3:	ShowActionDetailMenu(client, ACT_Z_MOVE, ACT_MOVE);
			default:ShowEditMenu(client);
		}
	}
	return 0;
}
public int Axis2MenuFunc(Handle menu, MenuAction action, int client, int param2){
	if (action == MenuAction_Select){
		switch(param2){ 
			//angle｛y,z,x｝
			// case 1:	ShowActionDetailMenu(client, ACT_X_ROTATE, ACT_ROTATE);
			// case 2:	ShowActionDetailMenu(client, ACT_Y_ROTATE, ACT_ROTATE);
			// case 3:	ShowActionDetailMenu(client, ACT_Z_ROTATE, ACT_ROTATE);

			// FORCE Z ROTATE ALLOW ONLY (The rotate function waste too much time 
			// because button and trigger brush entity strange appearence after input "setParent")
			case 1:	ShowActionDetailMenu(client, ACT_Z_ROTATE, ACT_ROTATE);
			default:ShowEditMenu(client);
		}
	}
	return 0;
}
//////////////////选择移动距离的菜单//////////////////
void ShowActionDetailMenu(int client, int axis, int action){//action 0 move; 1 rotate
	if(s_Select < 1) {
		ShowEditMenu(client);
		return;
	}
	char line[512];
	char s_axis[4];
	if(action == ACT_MOVE){
		if(axis == ACT_X_MOVE) s_axis = "X";
		else if(axis == ACT_Y_MOVE) s_axis = "Y";
		else s_axis = "Z";
	}
	else{
		if(axis == ACT_X_ROTATE) s_axis = "X";
		else if(axis == ACT_Y_ROTATE) s_axis = "Y";
		else s_axis = "Z";	
	}
	FormatEx(line, 512, "老虎机\n══════════════\n▶ 编辑对象: %d 号 \n▶ %s轴: %s 轴 \n══════════════", s_Select, action == ACT_MOVE ? "移动":"旋转", s_axis);
	IntToString(axis, s_axis, 4);
	//主菜单
	Menu g_hMenuMoveDetail;
	if(action == ACT_MOVE) g_hMenuMoveDetail = new Menu(MoveDetailMenuHandler);
	else g_hMenuMoveDetail = new Menu(RotateDetailMenuHandler);
	g_hMenuMoveDetail.SetTitle(line);
	g_hMenuMoveDetail.AddItem(s_axis,"+1");
	g_hMenuMoveDetail.AddItem(s_axis,"+10");
	g_hMenuMoveDetail.AddItem(s_axis,"+100");
	g_hMenuMoveDetail.AddItem(s_axis,"-1");
	g_hMenuMoveDetail.AddItem(s_axis,"-10");
	g_hMenuMoveDetail.AddItem(s_axis,"-100");
	g_hMenuMoveDetail.ExitBackButton = true;	
	// g_hMenuMoveDetail.ExitButton = true;	
	g_hMenuMoveDetail.Display(client, MENU_TIME_FOREVER);
}
public int MoveDetailMenuHandler(Menu menu, MenuAction action, int client, int index){
	if (action == MenuAction_Select){
		//获取轴
		char sTemp[4];
		menu.GetItem(index, sTemp, sizeof(sTemp));
		int axis = StringToInt(sTemp);
		float distance = Pow(10.00, float(index % 3));
		switch(index){
			case 0, 1, 2: MoveMachine(distance, axis);
			case 3, 4, 5: MoveMachine(distance * -1, axis);
		}
		ShowActionDetailMenu(client, axis, ACT_MOVE);
	}
	//返回轴向菜单
	if( action == MenuAction_Cancel ){
		if( index == MenuCancel_ExitBack ) ShowAxisMenu(client, ACT_MOVE);
	}
	if (action == MenuAction_End) delete menu;
	return 0;
}
public int RotateDetailMenuHandler(Menu menu, MenuAction action, int client, int index){
	if (action == MenuAction_Select){
		//获取轴
		char sTemp[4];
		menu.GetItem(index, sTemp, sizeof(sTemp));
		int axis = StringToInt(sTemp);
		float distance = Pow(10.00, float(index % 3));
		switch(index){
			case 0, 1, 2: RotateMachine(distance, axis);
			case 3, 4, 5: RotateMachine(distance * -1, axis);
		}
		ShowActionDetailMenu(client, axis, ACT_ROTATE);
	}
	//返回轴向菜单
	if( action == MenuAction_Cancel ){
		if( index == MenuCancel_ExitBack ) ShowEditMenu(client);
	}
	if (action == MenuAction_End) delete menu;
	return 0;
}
/* 
==============================================

 // MARK: - Placement Function

==============================================
 */
//移动功能实现
void RotateMachine(float degrees, int axis){
	SlotMachine prop;
	machineList.GetArray(s_Select - 1, prop);
	int Body_Index = EntRefToEntIndex(prop.Body);
	int Button_Index = EntRefToEntIndex(prop.Button);
	int Trigger_Index = EntRefToEntIndex(prop.Trigger);
	//检测区不需要Z轴以外的旋转
	if(Trigger_Index != INVALID_ENT_REFERENCE){
		if(axis != ACT_Z_ROTATE){
			AcceptEntityInput(prop.Trigger, "ClearParent");
		}
	}
	if(Button_Index != INVALID_ENT_REFERENCE && Body_Index != INVALID_ENT_REFERENCE && Trigger_Index != INVALID_ENT_REFERENCE){
		SetVariantString("!activator");
		AcceptEntityInput(prop.Button, "SetParent", prop.Body);
		float vPos[3], vAng[3];
		GetEntPropVector(prop.Body, Prop_Send, "m_vecOrigin", vPos);
		GetEntPropVector(prop.Body, Prop_Data, "m_angRotation", vAng);
		vAng[axis] = float(RoundFloat(vAng[axis] + degrees) % 360);
		TeleportEntity(prop.Body, NULL_VECTOR, vAng, NULL_VECTOR);
		//为什么要清除按钮父级？
		//当按钮有父级的时候被按一次后就会被传送到迷之位置，原因不明
		AcceptEntityInput(prop.Button, "ClearParent");
		//为什么要删除按钮重新生成一次？
		//按钮生成后如果被移动，按下后会往初始生成位置移动，即使设置了按下不移动的flag并且把移动速度归0，原因不明
		char targetname[32];
		GetEntPropVector(prop.Button, Prop_Send, "m_vecOrigin", vPos);
		GetEntPropVector(prop.Button, Prop_Data, "m_angRotation", vAng);
		GetEntPropString(prop.Button, Prop_Data, "m_iName", targetname, sizeof(targetname));
		AcceptEntityInput(prop.Button, "Kill");
		//input vpos要生成的坐标 targetname 重新生成后的名字 prop 更新按钮所属对象里按钮的ref
		RespawnButton(vPos, vAng, targetname, prop);

/* 		AcceptEntityInput(prop.Trigger, "ClearParent");
		GetEntPropVector(prop.Trigger, Prop_Send, "m_vecOrigin", vPos);
		GetEntPropVector(prop.Trigger, Prop_Data, "m_angRotation", vAng);
		GetEntPropString(prop.Trigger, Prop_Data, "m_iName", targetname, sizeof(targetname));
		AcceptEntityInput(prop.Trigger, "Kill");
		RespawnTrigger(vPos, vAng, targetname, prop);
		SetVariantString("!activator");
		AcceptEntityInput(prop.Trigger, "SetParent", prop.Body); */
		machineList.SetArray(s_Select - 1, prop);
	}
	//检测区重新绑定
	if(Trigger_Index != INVALID_ENT_REFERENCE && Body_Index != INVALID_ENT_REFERENCE){
		if(axis != ACT_Z_ROTATE){//不是z轴旋转，结束后重新绑定
			SetVariantString("!activator");
			AcceptEntityInput(prop.Trigger, "SetParent", prop.Body);
		}
	}
}
//移动功能实现
void MoveMachine(float distance, int axis){
	SlotMachine prop;
	machineList.GetArray(s_Select - 1, prop);
	int Button_Index = EntRefToEntIndex(prop.Button);
	if(Button_Index != INVALID_ENT_REFERENCE){
		int Body_Index = EntRefToEntIndex(prop.Body);
		if(Body_Index != INVALID_ENT_REFERENCE){
			SetVariantString("!activator");
			AcceptEntityInput(prop.Button, "SetParent", prop.Body);
			float vPos[3];
			GetEntPropVector(prop.Body, Prop_Send, "m_vecOrigin", vPos);
			vPos[axis] += distance;
			TeleportEntity(prop.Body, vPos, NULL_VECTOR, NULL_VECTOR);
			//为什么要清除按钮父级？
			//当按钮有父级的时候被按一次后就会被传送到迷之位置，原因不明
			AcceptEntityInput(prop.Button, "ClearParent");
			//为什么要删除按钮重新生成一次？
			//按钮生成后如果被移动，按下后会往初始生成位置移动，即使设置了按下不移动的flag并且把移动速度归0，原因不明
			char targetname[32];
			GetEntPropVector(prop.Button, Prop_Send, "m_vecOrigin", vPos);
			GetEntPropString(prop.Button, Prop_Data, "m_iName", targetname, sizeof(targetname));
			AcceptEntityInput(prop.Button, "Kill");
			//input vpos要生成的坐标 targetname 重新生成后的名字 prop 更新按钮所属对象里按钮的ref
			RespawnButton(vPos, NULL_VECTOR, targetname, prop);
			machineList.SetArray(s_Select - 1, prop);
		}
	}
}
void RespawnButton(const float vPos[3], const float vAng[3], const char targetname[32], SlotMachine prop){
	int button_Index = CreateEntityByName("func_button");
	prop.Button = EntIndexToEntRef(button_Index);
	DispatchKeyValue(prop.Button, "targetname", targetname);
	DispatchKeyValue(prop.Button, "solid", "0");
	DispatchKeyValue(prop.Button, "spawnflags", "1025");
	DispatchKeyValue(prop.Button, "wait", "0.1");
	DispatchKeyValue(prop.Button, "lip", "0");
	DispatchKeyValue(prop.Button, "speed", "0");
	DispatchKeyValue(prop.Button, "movedir", "0");
	TeleportEntity(prop.Button, vPos, vAng, NULL_VECTOR);//必须写在生成前
	DispatchSpawn(prop.Button);
	SetEntPropVector(prop.Button, Prop_Send, "m_vecMins", {-20.0,-26.0,-29.0});
	SetEntPropVector(prop.Button, Prop_Send, "m_vecMaxs", {20.0,26.0,29.0});
	HookSingleEntityOutput(prop.Button,"OnPressed", OnUseButton);
}
/* void RespawnTrigger(const float vPos[3], const float vAng[3], const char targetname[32], SlotMachine prop){
	int trigger_Index = CreateEntityByName("trigger_multiple");
	prop.Trigger = EntIndexToEntRef(trigger_Index);
	DispatchKeyValue(prop.Trigger, "targetname", targetname);
	DispatchKeyValue(prop.Trigger, "spawnflags", "1");
	SetEntityModel(prop.Trigger, s_models[2]);
	TeleportEntity(prop.Trigger, vPos, vAng, NULL_VECTOR);
	DispatchSpawn(prop.Trigger);
	SetEntPropVector(prop.Trigger, Prop_Send, "m_vecMins", {-110.0,-110.0,-128.0});
	SetEntPropVector(prop.Trigger, Prop_Send, "m_vecMaxs", {110.0,110.0,128.0});
	SetEntProp(prop.Trigger, Prop_Send, "m_nSolidType", 2);
	SetVariantString("!activator");
	AcceptEntityInput(prop.Trigger, "SetParent", prop.Body);
	HookSingleEntityOutput(prop.Trigger, "OnEndTouch", OnEndTouch);
} */
//开关所编辑的老虎机高亮
void MakeGlow(int select, bool glow = true){
	if(machineList == null || machineList.Length <= 0) return;
	//初始化永远选择最后生成的老虎机
	s_Select = select;
	//关闭所有的光圈，无论有没有开启都关闭，消耗更大但是更安全
	for(int i = 0; i < machineList.Length; i++){
		SlotMachine prop;
		machineList.GetArray(i, prop);
		int Body_Index = EntRefToEntIndex(prop.Body);
		if(Body_Index != INVALID_ENT_REFERENCE){
			ToggleGlow(prop.Body, false);
		}
	}
	if(glow){
		//开启所用的光圈
		SlotMachine prop;
		machineList.GetArray(s_Select - 1, prop);
		int Body_Index = EntRefToEntIndex(prop.Body);
		if(Body_Index != INVALID_ENT_REFERENCE){
			ToggleGlow(prop.Body, glow);
		}
	}
}
void SelectToggle(int action){
	if(machineList.Length <= 1) return;
	MakeGlow(s_Select, false);
	if(action == ACT_SELECT_NEXT) s_Select = s_Select >= machineList.Length ? 1 : s_Select + 1;
	else s_Select = s_Select > 1 ? s_Select - 1 :  machineList.Length;
	//让编辑对象高亮
	MakeGlow(s_Select);
}

//重新载入
void Reload(int client){
	DeleteAll(client);
	//shitty game update cause SetCommandFlags() laggy running :(
	//社区某次sb跟新导致了SetCommandFlags()函数的延迟
	CreateTimer(0.1, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
}
void DeleteLast(){
	SlotMachine prop;
	machineList.GetArray(s_Select - 1, prop);
	int Body_Index = EntRefToEntIndex(prop.Body);
	if(Body_Index != INVALID_ENT_REFERENCE){
		AcceptEntityInput(prop.Body, "KillHierarchy");
	}
	int Button_Index = EntRefToEntIndex(prop.Button);
	if(Button_Index != INVALID_ENT_REFERENCE){
		AcceptEntityInput(prop.Button, "Kill");
	}
	machineList.Erase(s_Select - 1);
	s_Select = machineList.Length > 0 ? machineList.Length : 0;
	// s_Select = machineList.Length > 1 ? machineList.Length - 1 : machineList.Length;
}
/* 
==============================================

 // MARK: - 	Spawn & Save

==============================================
 */
 //kv
void BuildFileDirectories(){
	char FolderPath[] = "addons/sourcemod/data/slotmachines";
	if(!DirExists(FolderPath)) CreateDirectory(FolderPath,509);
	//不应该在这里创建或读取配置，应该在每回合开始
	// BuildPath(Path_SM, SavePath, sizeof(SavePath), "data/slotmachines/slotmachine.txt");
	// KvStore = new KeyValues("Slotmachine");
	// if (FileExists(SavePath)) KvStore.ImportFromFile(SavePath);//蒋文件转换为kv树数据
	// else KvStore.ExportToFile(SavePath); //创建txt文件，不判断是否存在会直接覆盖
}

public void Event_RoundStart(Event event, const char[] name, bool dontbroadcast){
	CreateTimer(0.5, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action TimerStart(Handle timer){
	// PrintToServer("载入道具");
	LoadSpawns();
	return Plugin_Continue;
}

void LoadSpawns(){
	//每次生成前清理arraylist
	if(machineList.Length !=0){
		delete machineList;
		machineList = new ArrayList(sizeof(SlotMachine));	
	}
	s_Count = 0;
	s_Select = 0;
	//储存相关
	KeyValues KvMachine = new KeyValues("SlotMachine");
	char SavePath[PLATFORM_MAX_PATH];
	char map[256];//地图名称
	//获取地图名称map
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, SavePath, sizeof(SavePath), "data/slotmachines/%s.txt", map);
	if (FileExists(SavePath)){ 
		//蒋文件转换为kv树数据
		KvMachine.ImportFromFile(SavePath);
		KvMachine.Rewind();
		KvMachine.JumpToKey("total_cache");
		int max = KvMachine.GetNum("total", 0);
		KvMachine.Rewind();
		if(max <= 0 || entityCount() > 1900){ //防止太多实体炸服 一张图最多允许2048,我还额外给地图预留了148个槽位
			delete KvMachine;
			return;
		}
		for(int count=0; count < max; count++){
			char tmp[8];
			IntToString(count, tmp, 8);
			if(KvMachine.JumpToKey(tmp)){
				float VecOrigin[3];
				float VecAngles[3];
				KvMachine.GetVector("Origin", VecOrigin); //  keyvalues.inc
				KvMachine.GetVector("Angles", VecAngles); //  keyvalues.inc
				SpawnSlotMachine(VecOrigin, VecAngles);
			}
			KvMachine.Rewind();
		}
	}
	else{
		//创建txt文件，不判断是否存在会直接覆盖
		KvMachine.ExportToFile(SavePath); 
		PrintToChatAll("创建配置");
	}
	delete KvMachine;
}

void SpawnSlotMachine(const float Origin[3], const float Angles[3]){
	if(s_Count >= MAX_MACHINE) return;
	float VecOrigin[3];
	VecOrigin = Origin;
	float VecAngles[3];
	VecAngles = Angles;
	//只保留z轴旋转
	VecAngles[0] = 0.00;
	VecAngles[2] = 0.00;

	char targetname[32];
	SlotMachine prop;

	int Body_Index = CreateEntityByName("prop_dynamic_override");
	prop.Body = EntIndexToEntRef(Body_Index);
	DispatchKeyValue(prop.Body, "model", s_models[0]);
	DispatchKeyValue(prop.Body, "solid", "0");
	FormatEx(targetname,32,"l4d2@SlotMachine%d@Body",s_Count);
	DispatchKeyValue(prop.Body, "targetname", targetname);
	DispatchSpawn(prop.Body);
	TeleportEntity(prop.Body, VecOrigin, NULL_VECTOR, NULL_VECTOR);

	int w_Index2 = CreateEntityByName("prop_dynamic_override");
	prop.w_Index2 = EntIndexToEntRef(w_Index2);
	DispatchKeyValue(prop.w_Index2, "model", s_models[1]);
	DispatchKeyValue(prop.w_Index2, "solid", "0");
	FormatEx(targetname,32,"l4d2@SlotMachine%d@Wheel2",s_Count);
	DispatchKeyValue(prop.w_Index2, "targetname", targetname);
	DispatchKeyValue(prop.w_Index2, "DefaultAnim", "cherry");
	DispatchSpawn(prop.w_Index2);
	float VecOrigin2[3];
	VecOrigin2 = VecOrigin;
	VecOrigin2[2] += 37; 
	TeleportEntity(prop.w_Index2, VecOrigin2, NULL_VECTOR, NULL_VECTOR);
	SetVariantString("!activator");
	AcceptEntityInput(prop.w_Index2, "SetParent", prop.Body);

	int w_Index = CreateEntityByName("prop_dynamic_override");
	prop.w_Index = EntIndexToEntRef(w_Index);
	DispatchKeyValue(prop.w_Index, "model", s_models[1]);
	DispatchKeyValue(prop.w_Index, "solid", "0");
	FormatEx(targetname,32,"l4d2@SlotMachine%d@Wheel",s_Count);
	DispatchKeyValue(prop.w_Index, "targetname", targetname);
	DispatchKeyValue(prop.w_Index, "DefaultAnim", "cherry");
	DispatchSpawn(prop.w_Index);
	float VecOrigin3[3];
	VecOrigin3 = VecOrigin;
	VecOrigin3[0] -= 10; 
	VecOrigin3[2] += 37; 
	TeleportEntity(prop.w_Index, VecOrigin3, NULL_VECTOR, NULL_VECTOR);
	SetVariantString("!activator");
	AcceptEntityInput(prop.w_Index, "SetParent", prop.Body);

	int w_Index3 = CreateEntityByName("prop_dynamic_override");
	prop.w_Index3 = EntIndexToEntRef(w_Index3);
	DispatchKeyValue(prop.w_Index3, "model", s_models[1]);
	DispatchKeyValue(prop.w_Index3, "solid", "0");
	FormatEx(targetname,32,"l4d2@SlotMachine%d@Wheel3",s_Count);
	DispatchKeyValue(prop.w_Index3, "targetname", targetname);
	DispatchKeyValue(prop.w_Index3, "DefaultAnim", "cherry");
	DispatchSpawn(prop.w_Index3);
	float VecOrigin4[3];
	VecOrigin4 = VecOrigin;
	VecOrigin4[0] += 10; 
	VecOrigin4[2] += 37; 
	TeleportEntity(prop.w_Index3, VecOrigin4, NULL_VECTOR, NULL_VECTOR);
	SetVariantString("!activator");
	AcceptEntityInput(prop.w_Index3, "SetParent", prop.Body);

	int trigger_Index = CreateEntityByName("trigger_multiple");
	prop.Trigger = EntIndexToEntRef(trigger_Index);
	FormatEx(targetname,32,"l4d2@SlotMachine%d@Trigger",s_Count);
	DispatchKeyValue(prop.Trigger, "targetname", targetname);
	DispatchKeyValue(prop.Trigger, "spawnflags", "1");
	SetEntityModel(prop.Trigger, s_models[2]);
	// GetEntPropVector(Body_Index, Prop_Send, "m_vecOrigin", VecOrigin);
	float VecOrigin6[3];
	VecOrigin6 = VecOrigin;
	//我不得不拉大检测范围来防止玩家在范围外启动机器造成一些bug
	// VecOrigin6[0] += 2; 
	// VecOrigin6[1] -= 61; 
	VecOrigin6[2] += 64; 
	TeleportEntity(prop.Trigger, VecOrigin6, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(prop.Trigger);
	SetEntPropVector(prop.Trigger, Prop_Send, "m_vecMins", {-110.0,-110.0,-128.0});
	SetEntPropVector(prop.Trigger, Prop_Send, "m_vecMaxs", {110.0,110.0,128.0});
	SetEntProp(prop.Trigger, Prop_Send, "m_nSolidType", 2);
	SetVariantString("!activator");
	AcceptEntityInput(prop.Trigger, "SetParent", prop.Body);
	// HookSingleEntityOutput(prop.Trigger, "OnStartTouch", OnStartTouch);
	HookSingleEntityOutput(prop.Trigger, "OnEndTouch", OnEndTouch);

	int button_Index = CreateEntityByName("func_button");
	prop.Button = EntIndexToEntRef(button_Index);
	float VecOrigin5[3];
	VecOrigin5 = VecOrigin;
	VecOrigin5[0] += 2; 
	VecOrigin5[1] -= 3; 
	VecOrigin5[2] += 29; 
	TeleportEntity(prop.Button, VecOrigin5, NULL_VECTOR, NULL_VECTOR);//必须写在生成前
	DispatchSpawn(prop.Button);
	SetVariantString("!activator");
	AcceptEntityInput(prop.Button, "SetParent", prop.Body);
	//旋转老虎机
	TeleportEntity(prop.Body, NULL_VECTOR, VecAngles, NULL_VECTOR);
	//解绑按钮，按新位置和角度重新生成(别问为啥要重新生成，按钮设定父级后表现诡异，即使解绑)
	AcceptEntityInput(prop.Button, "ClearParent");
	GetEntPropVector(prop.Button, Prop_Send, "m_vecOrigin", VecOrigin5);
	GetEntPropVector(prop.Button, Prop_Data, "m_angRotation", VecAngles);
	AcceptEntityInput(prop.Button, "Kill");
	FormatEx(targetname,32,"l4d2@SlotMachine%d@Button",s_Count);
	RespawnButton(VecOrigin5, VecAngles, targetname, prop);

/* 	int button_Index = CreateEntityByName("func_button");
	prop.Button = EntIndexToEntRef(button_Index);
	// SetEntityModel(prop.Button,  s_models[0]);
	FormatEx(targetname,32,"l4d2@SlotMachine%d@Button",s_Count);
	DispatchKeyValue(prop.Button, "targetname", targetname);
	DispatchKeyValue(prop.Button, "solid", "0");
	DispatchKeyValue(prop.Button, "spawnflags", "1025");
	DispatchKeyValue(prop.Button, "wait", "0.1");
	DispatchKeyValue(prop.Button, "lip", "0");
	DispatchKeyValue(prop.Button, "speed", "0");
	DispatchKeyValue(prop.Button, "movedir", "0");
	float VecOrigin5[3];
	VecOrigin5 = VecOrigin;
	VecOrigin5[0] += 2; 
	VecOrigin5[1] -= 3; 
	VecOrigin5[2] += 29; 
	TeleportEntity(prop.Button, VecOrigin5, NULL_VECTOR, NULL_VECTOR);//必须写在生成前
	DispatchSpawn(prop.Button);
	SetEntPropVector(prop.Button, Prop_Send, "m_vecMins", {-20.0,-26.0,-29.0});
	SetEntPropVector(prop.Button, Prop_Send, "m_vecMaxs", {20.0,26.0,29.0});
	// SetEntProp(prop.Button, Prop_Send, "m_nSolidType", 2);
	// SetEntProp(prop.Button, Prop_Data, "m_iParent", prop.Body);
	// SetVariantString("!activator");
	// AcceptEntityInput(prop.Button, "SetParent", prop.Body);
	HookSingleEntityOutput(prop.Button,"OnPressed", OnUseButton);
	// ClientCommand(client, "slot10"); */

	machineList.PushArray(prop);
	s_Count += 1;
	s_Select = machineList.Length;
}

void SpawnMachineAtCrosshair(int client){
	if(s_Count >= MAX_MACHINE || entityCount() > 1900) return; //防止太多实体炸服 一张图最多允许2048
	float VecOrigin[3];
	float VecAngles[3];

	GetClientEyePosition(client, VecOrigin);
	GetClientEyeAngles(client, VecAngles);
	TR_TraceRayFilter(VecOrigin, VecAngles, MASK_OPAQUE, RayType_Infinite, TraceRayDontHitSelf, client);
	if(TR_DidHit(null)) TR_GetEndPosition(VecOrigin);
	else PrintToChat(client, "[SM] 距离超出范围");
	//生成
	SpawnSlotMachine(VecOrigin, NULL_VECTOR);
}

//保存地图上摆放的机器
void SaveMachine(){
	char SavePath[PLATFORM_MAX_PATH];
	char map[256];//地图名称
	//获取地图名称map
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, SavePath, sizeof(SavePath), "data/slotmachines/%s.txt", map);

	KeyValues KvMachine = new KeyValues("SlotMachine");
	KvMachine.JumpToKey("total_cache", true);
	KvMachine.SetNum("total", machineList.Length);
	KvMachine.Rewind();

	for(int i; i < machineList.Length; i++ ){
		SlotMachine p;
		machineList.GetArray(i, p);
		int Body_Index = EntRefToEntIndex(p.Body);
		if(Body_Index != INVALID_ENT_REFERENCE){
			float vPos[3], vAng[3];
			GetEntPropVector(p.Body, Prop_Send, "m_vecOrigin", vPos);
			GetEntPropVector( p.Body, Prop_Data, "m_angRotation", vAng);
			// GetEntPropVector(p.Body, Prop_Send, "m_vecAngles", vAng);
			char id[32]
			Format(id, 32, "%d", i);
			KvMachine.JumpToKey(id, true);
			KvMachine.SetVector("Origin", vPos);  //  keyvalues.inc
			KvMachine.SetVector("Angles", vAng);  //  keyvalues.inc
			KvMachine.Rewind();
		}
	}
	KvMachine.ExportToFile(SavePath);
	delete KvMachine;
}

void DeleteAll(int client){
	CheatCommand(client, "ent_fire", "l4d2@slotmachine* KillHierarchy");
	delete machineList;
	machineList = new ArrayList(sizeof(SlotMachine));
	s_Count = 0;
	s_Select = 0;
}
/* 
==============================================

 // MARK: - Entity Output

==============================================
 */
 //使用机器相关
public void OnUseButton(const char[] output, int caller, int activator, float delay){
	if(!isSurvivor(activator)) return;
	//寻找数组中对应使用的对象
	SlotMachine prop;
	int i;
	for(; i < machineList.Length; i++){
		SlotMachine p;
		machineList.GetArray(i, p);
		if(caller == EntRefToEntIndex(p.Button)){
			machineList.GetArray(i, prop);
			#if DEBUG
				PrintToChatAll("ref: %d", p.Button);
				PrintToChatAll("index :%d", caller);
			#endif
			break;
		}
	}
	if(prop.isRotate && prop.w_Owner == activator){//是使用者使用
		#if DEBUG
			PrintToChatAll("是使用者使用");
		#endif
		stop(activator, prop);
	}
	else{//第一次启动
		#if DEBUG
			PrintToChatAll("第一次启动");
		#endif
		//检测当前用户是否已经启动过机器，防止同时启动多台
		for(int k; k < machineList.Length; k++){
			SlotMachine p;
			machineList.GetArray(k, p);
			if(activator == p.w_Owner){
				return;
			}
		}
		start(activator, prop);
	}
	machineList.SetArray(i, prop);
}
//离开机器检测相关
public void OnEndTouch(const char[] output, int caller, int activator, float delay){
	if(!isSurvivor(activator)) return;
	#if DEBUG
		PrintToChatAll("OnEndTouch");
	#endif
	//匹配机器
	SlotMachine prop;
	int i;
	for(; i < machineList.Length; i++ ){
		SlotMachine p;
		machineList.GetArray(i, p);
		if(caller == EntRefToEntIndex(p.Trigger)){
			machineList.GetArray(i, prop);
			#if DEBUG
				PrintToChatAll("ref: %d", p.Trigger);
				PrintToChatAll("index :%d", caller);
			#endif
			break;
		}
	}
	//机器运行时，玩家离开机器，机器重置
	if(activator == prop.w_Owner){
		#if DEBUG
			PrintToChatAll("%d已离开", activator);
		#endif
		//返回积分
		if(!IsPlayerIncapped(prop.w_Owner)){
			int health = GetEntProp(prop.w_Owner, Prop_Data, "m_iHealth");
			if(health > NORMAL_COST){
				SetEntProp(prop.w_Owner, Prop_Data, "m_iHealth", health + NORMAL_COST);
				PrintToChat(prop.w_Owner,"\x03中断操作! 返还\x04 %d \x03HP!", NORMAL_COST)
			}
		}
		//
		prop.w_Owner = 0;
		prop.w_stopCount = 0;
		prop.isRotate = false;
		prop.w_result = {0,0,0};
		machineList.SetArray(i, prop);
		//停止轮子滚动动画
		int w_Index = EntRefToEntIndex(prop.w_Index);
		int w_Index2 = EntRefToEntIndex(prop.w_Index2);
		int w_Index3 = EntRefToEntIndex(prop.w_Index3);
		if(w_Index != INVALID_ENT_REFERENCE){
			SetVariantString("cherry");
			AcceptEntityInput(w_Index, "SetAnimation");
		}
		if(w_Index2 != INVALID_ENT_REFERENCE){
			SetVariantString("cherry");
			AcceptEntityInput(w_Index2, "SetAnimation");
		}
		if(w_Index3 != INVALID_ENT_REFERENCE){
			SetVariantString("cherry");
			AcceptEntityInput(w_Index3, "SetAnimation");
		}
		StopSoundPerm(activator, "rockBody.mp3");
		EmitSoundToClient(activator, s_sounds[5]);
		// ClientCommand(activator, "slot10");
	}
	//当机器使用结束后，最后的使用者离开时重置机器图标
	if(!prop.isRotate && activator == prop.w_LastOwner){
		prop.w_LastOwner = 0;
		prop.w_result = {0,0,0};
		machineList.SetArray(i, prop);
		//停止轮子滚动动画
		int w_Index = EntRefToEntIndex(prop.w_Index);
		int w_Index2 = EntRefToEntIndex(prop.w_Index2);
		int w_Index3 = EntRefToEntIndex(prop.w_Index3);
		if(w_Index != INVALID_ENT_REFERENCE){
			SetVariantString("cherry");
			AcceptEntityInput(w_Index, "SetAnimation");
		}
		if(w_Index2 != INVALID_ENT_REFERENCE){
			SetVariantString("cherry");
			AcceptEntityInput(w_Index2, "SetAnimation");
		}
		if(w_Index3 != INVALID_ENT_REFERENCE){
			SetVariantString("cherry");
			AcceptEntityInput(w_Index3, "SetAnimation");
		}
	}
}
/* 
==============================================

 // MARK: - Machine Logic

==============================================
 */
//启动机器相关
void start(int client, SlotMachine prop){
	// 倒地不允许用
	if(IsPlayerIncapped(client)) return;
	int health = GetEntProp(client, Prop_Data, "m_iHealth");
	#if DEBUG
		PrintToChatAll("%d", health);
	#endif
	// 血量不够不让用！
	if(health <= NORMAL_COST) return;
	SetEntProp(client, Prop_Data, "m_iHealth", health - NORMAL_COST);
	EmitSoundToClient(client, "rockBody.mp3");
	// p_credits = p_credits - NORMAL_COST;
	// PrintToChat(client, "\x03点券剩余:\x04 %d", p_credits);
	prop.w_Owner = client;
	prop.w_LastOwner = client;
	prop.isRotate = true;
	prop.w_stopCount = 0;
	prop.w_result = {0,0,0};
	//播放轮子和机器动画
	int Body_Index = EntRefToEntIndex(prop.Body);
	int w_Index = EntRefToEntIndex(prop.w_Index);
	int w_Index2 = EntRefToEntIndex(prop.w_Index2);
	int w_Index3 = EntRefToEntIndex(prop.w_Index3);
	if(Body_Index != INVALID_ENT_REFERENCE){
		SetVariantString("rotate");
		AcceptEntityInput(Body_Index, "SetAnimation");
	}
	if(w_Index != INVALID_ENT_REFERENCE){
		SetVariantString("rotate");
		AcceptEntityInput(w_Index, "SetAnimation");
	}
	if(w_Index2 != INVALID_ENT_REFERENCE){
		SetVariantString("rotate");
		AcceptEntityInput(w_Index2, "SetAnimation");
	}
	if(w_Index3 != INVALID_ENT_REFERENCE){
		SetVariantString("rotate");
		AcceptEntityInput(w_Index3, "SetAnimation");
	}
}
//停止轮子相关
void stop(int client, SlotMachine prop){
	//随机结果
	int icon = GetRandomInt(0, ICONS_COUNT - 1);
	//结果
	int ref;
	switch(prop.w_stopCount){
		case 0:{
			ref = prop.w_Index;
		}
		case 1:{
			ref = prop.w_Index2;
		}
		case 2:{
			ref = prop.w_Index3;
		}
	}
	int index = EntRefToEntIndex(ref);
	if(index != INVALID_ENT_REFERENCE){
		SetVariantString(w_Icons[icon][3]);
		AcceptEntityInput(index, "SetAnimation");
	}
	prop.w_result[prop.w_stopCount] = icon;
	#if DEBUG
		PrintToChatAll("\x03数字为:\x04 %d", prop.w_result[prop.w_stopCount]);
	#endif
	if(prop.w_stopCount > WHEEL_COUNT - 2) {// 0 ，1 ，第三次计算结果
		prop.w_stopCount = 0;
		prop.isRotate = false;
		prop.w_Owner = 0;
		StopSoundPerm(client, s_sounds[4]);
		compareResult(client, prop);
	}
	else{
		prop.w_stopCount += 1;
		EmitSoundToClient(client, s_sounds[0]);
	}
}
//比较结果
void compareResult(int client, const SlotMachine prop){
	int icon1 = prop.w_result[0];
	int icon2 = prop.w_result[1];
	int icon3 = prop.w_result[2];
	#if DEBUG
		PrintToChatAll("\x03结果为:\x04 %d %d %d", icon1, icon2, icon3);
	#endif
	if(icon1 == icon2 && icon2 == icon3){//3个一样
		char s_name[8];
		FormatEx(s_name, 8, "%s", w_Icons[icon2][0]);
		int credits = StringToInt(w_Icons[icon2][2]);
		// p_credits = p_credits + credits;
		int health = GetEntProp(client, Prop_Data, "m_iHealth");
		int addHP = health + credits;
		int max = GetEntProp(client, Prop_Send, "m_iMaxHealth");
		if(addHP > max){
			SetEntProp(client, Prop_Send, "m_iMaxHealth", addHP);
		}
		SetEntProp(client, Prop_Data, "m_iHealth", addHP);
		EmitSoundToClient(client, s_sounds[1]);
		EmitSoundToClient(client, s_sounds[2]);
		PrintToChat(client, "\x03恭喜中奖! \x043 \x03个\x04 %s \x03, 奖励\x04 %d \x03HP!", s_name, credits);
		// PrintToChat(client, "\x03恭喜中奖! \x043 \x03个\x04 %s \x03, 奖励\x04 %d \x03分! \x04(积分：%d)", s_name, credits, p_credits);
	}
	else if(icon1 == icon2 || icon2 == icon3){//2个一样
		char s_name[8];
		FormatEx(s_name, 8, "%s", w_Icons[icon2][0]);
		int credits = StringToInt(w_Icons[icon2][1]);
		// p_credits += credits;
		int health = GetEntProp(client, Prop_Data, "m_iHealth");
		int addHP = health + credits;
		int max = GetEntProp(client, Prop_Send, "m_iMaxHealth");
		if(addHP > max){
			SetEntProp(client, Prop_Send, "m_iMaxHealth", addHP);
		}
		SetEntProp(client, Prop_Data, "m_iHealth", addHP);
		EmitSoundToClient(client, s_sounds[2]);
		PrintToChat(client, "\x03恭喜中奖! \x042 \x03个\x04 %s \x03, 奖励\x04 %d \x03HP!", s_name, credits);
		// PrintToChat(client, "\x03恭喜中奖! \x042 \x03个\x04 %s \x03, 奖励\x04 %d \x03分! \x04(积分：%d)", s_name, credits, p_credits);
	}
	else{
		//too noisy
		EmitSoundToClient(client, s_sounds[3]);
	}
}
/* 
==============================================

 // MARK: - STOCK

==============================================
 */
stock bool TraceRayDontHitSelf(int entity, int mask, any data){
	return entity != data
}
//矩阵旋转
stock void GetZRotatePosition(const float vPos1[3], float vPos2[3], const float vAng[3]){
	// xB = xA + cos(θ)*(xB - xA) - sin(θ)*(yB - yA)
	// yB = yA + sin(θ)*(xB - xA) + cos(θ)*(yB - yA) 
	vPos2[0] = vPos1[0] + Cosine(vAng[1])*(vPos2[0] - vPos1[0]) - Sine(vAng[1])*(vPos2[1] - vPos1[1]);
	vPos2[1] = vPos1[1] + Sine(vAng[1])*(vPos2[0] - vPos1[0]) + Cosine(vAng[1])*(vPos2[1] - vPos1[1]);
}

// 创建武器轮廓
stock void ToggleGlow(int ref, bool turnOn = true){
	int index = EntRefToEntIndex(ref);
	if(index != INVALID_ENT_REFERENCE){
		if(turnOn){
			SetEntProp(index, Prop_Send, "m_iGlowType", 2);
			SetEntProp(index, Prop_Send, "m_glowColorOverride", GetColor("255 0 0"));
			SetEntProp(index, Prop_Send, "m_nGlowRange", 1900);
		}
		else{
			SetEntProp(index, Prop_Send, "m_iGlowType", 0);
			SetEntProp(index, Prop_Send, "m_glowColorOverride", 0);
			SetEntProp(index, Prop_Send, "m_nGlowRange", 0);
		}
	}
}
stock int GetColor(char[] sTemp){
	if (strcmp(sTemp, "") == 0) return 0;
	char sColors[3][4];
	int	 iColor = ExplodeString(sTemp, " ", sColors, 3, 4);
	if (iColor != 3) return 0;
	iColor = StringToInt(sColors[0]);
	iColor += 256 * StringToInt(sColors[1]);
	iColor += 65536 * StringToInt(sColors[2]);
	return iColor;
}

stock int entityCount(){
	int count = 0, ent = -1;
	while ((ent = FindEntityByClassname(ent, "*")) != -1)
	{
		count++;
	}
	#if DEBUG
		PrintToChatAll("[debug] entity count: %d", count);
	#endif
	return count;
}

//检测玩家是否倒地
stock bool IsPlayerIncapped(int client){
	return	GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1;
}

//判断玩家是否valid
stock bool isClientValid(int client, bool NoBot = true){
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	if (!IsClientInGame(client)) return false;
	if (NoBot){
		if (IsFakeClient(client)) return false;
	}
	return true;
}

//判断是否是人类
stock bool isSurvivor(int client){
	return isClientValid(client) && GetClientTeam(client) == 2;
}

stock StopSoundPerm(client, char[] sound){
	StopSound(client, SNDCHAN_AUTO, sound);
	StopSound(client, SNDCHAN_WEAPON, sound);
	StopSound(client, SNDCHAN_VOICE, sound);
	StopSound(client, SNDCHAN_ITEM, sound);
	StopSound(client, SNDCHAN_BODY, sound);
	StopSound(client, SNDCHAN_STREAM, sound);
	StopSound(client, SNDCHAN_VOICE_BASE, sound);
	StopSound(client, SNDCHAN_USER_BASE, sound);
}

stock CheatCommand(int client, const char[] command, const char[]arguments){
	if (!client) return;
	int admindata = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, admindata);
}
