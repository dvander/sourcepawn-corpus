#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>


new Handle:cvarEnable;
new bool:isEnabled;    //启动或禁用插件变量

// Functions
public Plugin:myinfo =
{
    name = "New_PlayerModel",
    author = "me",
    description = "Add New PlayerModel",
    version = "1.0",
    url = "http://forums.alliedmods.net"
}


static int RoundNum = 0;    //回合序号

//定义真人用户的人物数组
static int iEntPlayerModelList[128] = {-1};

static char NewPlayerModelNames[256][20];    //新人物名字数组
static char NewPlayerModelPath[256][128];    //新人物路径数组
static int NewPlayerModelType[256] = {0};    //新人物类型数组，0为警察，1为匪徒
static int IsBotsUseSNewModel[256] = {0};    //新人物允许Bot使用开关数组

//警察bot
static int iEntCTBotsModelList[128] = {-1};    //定义警察bot的人物数组
static char NewCTBotsModelPath[256][128];    //警察Bot新人物路径数组
static int ctbotsnum = 0;    //警察bot的人物数组大小

//匪徒bot
static int iEntTERBotsModelList[128] = {-1};    //定义匪徒bot的人物数组
static char NewTERBotsModelPath[256][128];    //匪徒Bot新人物路径数组
static int terbotsnum = 0;    //匪徒bot的人物数组大小

public OnPluginStart()
{
	//设置配置文件
	CreateConVar("sm_new_playermodel_version", "1.0.0", "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarEnable = CreateConVar("sm_playermodel_enable", "1", "Whether to enable the plugin (1: Enable the plugin. 0: disabled)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	AutoExecConfig(true, "plugin.new_playermodel");
	HookConVarChange(cvarEnable, CvarChange);
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("round_end", RoundEnd, EventHookMode_Pre);
}

public OnMapStart()
{
	ctbotsnum = 0;
	terbotsnum = 0;
	
	//读取新人物信息文件	
	new String:filepath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filepath, PLATFORM_MAX_PATH, "configs/NewPlayerModelInfo.txt");
	new Handle:file = OpenFile(filepath, "r"); 
	if(file != INVALID_HANDLE){
		
		decl String:fileline[256];
		decl String:data[8][256];
		static int num = 0;
		
		while(ReadFileLine(file, fileline, 256))
		{		
			if(ExplodeString(fileline, "><", data, 4, 256) == 4)
			{
				if(strlen(data[0]) > 0 && strlen(data[1]) > 0)
				{
					//将新人物信息文件的数据载入各个新武器信息数组
					TrimString(data[0]);
					TrimString(data[1]);
					TrimString(data[2]);
					TrimString(data[3]);
					
					if(strlen(data[0]) > 0)
					    ReplaceString(data[0], strlen(data[0]), "<", "");
					if(strlen(data[3]) > 0)
					    ReplaceString(data[3], strlen(data[3]), ">", "");
					
					new TempFlag = true;
					for(int i = 0; i <= (sizeof(NewPlayerModelNames) - 1); i++) {
						if(StrEqual(NewPlayerModelNames[i], data[0]))
						{
							TempFlag = false;
							break;
						}
					}
					if(TempFlag == false)
						continue;
					
					strcopy(NewPlayerModelNames[num], strlen(data[0]) + 1, data[0]);
					strcopy(NewPlayerModelPath[num], strlen(data[1]) + 1, data[1]);
					
					new PlayerModelType = 0;
					if(strlen(data[2]) > 0)
						PlayerModelType = StringToInt(data[2]);
				    NewPlayerModelType[num] = PlayerModelType;
					if(NewPlayerModelType[num] < 0 || NewPlayerModelType[num] > 1)
						NewPlayerModelType[num] = 0;
					
					new isBotsUse = 0;
					if(strlen(data[3]) > 0)
						isBotsUse = StringToInt(data[3]);
				    IsBotsUseSNewModel[num] = isBotsUse;
					if(IsBotsUseSNewModel[num] < 0 || IsBotsUseSNewModel[num] > 1)
						IsBotsUseSNewModel[num] = 0;
					
					num++;
				}
			    				
			}
			
		}	
		
		CloseHandle(file);		
	}
	
	//遍历各新人物信息数组，预载新人物模型文件
	for(int i = 0; i <= 255; i++) {
		if(strlen(NewPlayerModelNames[i]) > 0 && strlen(NewPlayerModelPath[i]) > 0)
		{
			decl String:PreStr0[] = "sm_";
			decl String:PreStr1[] = "models/player/";
			
			decl String:MyConsole[32];
			Format(MyConsole, sizeof(MyConsole), "%s%s", PreStr0, NewPlayerModelNames[i]);
			TrimString(MyConsole);
			RegConsoleCmd(MyConsole,Cmd_ChangePlayerModel);    //注册设置新人物的控制台命令
			
			decl String:Path1[64];
			Format(Path1, sizeof(Path1), "%s%s", PreStr1, NewPlayerModelPath[i]);
			TrimString(Path1);
			PrecacheModel(Path1);
			
			if(IsBotsUseSNewModel[i] == 1)
			{
				if(NewPlayerModelType[i] == 0)    //警察人物
				{
				    NewCTBotsModelPath[ctbotsnum] = NewPlayerModelPath[i];
					ctbotsnum++;
				}
				if(NewPlayerModelType[i] == 1)    //匪徒人物
				{
					NewTERBotsModelPath[terbotsnum] = NewPlayerModelPath[i];
					terbotsnum++;
				}
			}		
		}
	}
	
	//开局时清空索引
	for(int i = 0; i <= (sizeof(iEntPlayerModelList) - 1); i++) {
		iEntPlayerModelList[i] = -1;
	}
	for(int i = 0; i <= (sizeof(iEntCTBotsModelList) - 1); i++) {
		iEntCTBotsModelList[i] = -1;
	}
	for(int i = 0; i <= (sizeof(iEntTERBotsModelList) - 1); i++) {
		iEntTERBotsModelList[i] = -1;
	}
	
	AddCommandListener(OnJoinClass, "joinclass");    //监听选择人物的控制台命令
	RoundNum = 0;
}

//读取配置文件的cvar的值
public OnConfigsExecuted()
{
	isEnabled = GetConVarBool(cvarEnable);
}

//cvar值变化时的响应数组
public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if(convar == cvarEnable)
	{
		if(StringToInt(newValue) == 1)
		{
			isEnabled = true;
		}
		else
		{
			isEnabled = false;
		}
	}
}


//检测玩家属性函数
bool:IsClient(Client, bool:Alive)
{
	return Client <= MaxClients && IsClientConnected(Client) && IsClientInGame(Client) && (Alive && IsPlayerAlive(Client));
}


//设置新人物的控制台命令响应函数
public Action:Cmd_ChangePlayerModel(Client,Args){
	if(!Client)Client=1;
	
	decl String:sText[256]; 
	GetCmdArg(0, sText, sizeof(sText));    //获取输入的控制台命令内容
	StripQuotes(sText);
	TrimString(sText);
	ReplaceStringEx(sText, strlen(sText), "_", ";");
	decl String:ArgumentStr[2][30];
	ExplodeString(sText, ";", ArgumentStr, 2, 30);
	
	if(isEnabled == false)
	{
		PrintToChat(Client, "The plugin is disabled and you cannot select a new character model!");
		return;
	}
	
	//找到和用户输入设置新人物的控制台命令相匹配的新人物
	int num = -1;
	for(int i = 0; i <= (sizeof(NewPlayerModelNames) - 1); i++) {
		if(StrEqual(NewPlayerModelNames[i], ArgumentStr[1]))
		{
			num = i;
			break;
		}
	}
	
	if(num > -1)
	{
		if(NewPlayerModelType[num] == 0 && GetClientTeam(Client) == CS_TEAM_T)
		{
			PrintToChat(Client, "Tip: You cannot select a character from the opposing camp!");
		    return;
		}
		if(NewPlayerModelType[num] == 1 && GetClientTeam(Client) == CS_TEAM_CT)
		{
			PrintToChat(Client, "Tip: You cannot select a character from the opposing camp!");
		    return;
		}
		
		if(IsPlayerAlive(Client))
		{
			ForcePlayerSuicide(Client);
		}		
		else
		{
			if(GetClientTeam(Client) == CS_TEAM_CT)
			{
				if(RoundNum == 1)
				{
					RoundNum--;
					//清空Bot索引
	                for(int i = 0; i <= (sizeof(iEntCTBotsModelList) - 1); i++) {
		                iEntCTBotsModelList[i] = -1;
	                }
	                for(int i = 0; i <= (sizeof(iEntTERBotsModelList) - 1); i++) {
		                iEntTERBotsModelList[i] = -1;
	                }
				}					
				FakeClientCommand(Client, "joinclass 5");
			}			    
			if(GetClientTeam(Client) == CS_TEAM_T)
			{
				if(RoundNum == 1)
				{
					RoundNum--;
					//清空Bot索引
	                for(int i = 0; i <= (sizeof(iEntCTBotsModelList) - 1); i++) {
		                iEntCTBotsModelList[i] = -1;
	                }
	                for(int i = 0; i <= (sizeof(iEntTERBotsModelList) - 1); i++) {
		                iEntTERBotsModelList[i] = -1;
	                }
				}
					
				FakeClientCommand(Client, "joinclass 1");
			}				
			
			decl String:PreStr2[] = "models/player/";
		    decl String:Path2[64];
		    Format(Path2, sizeof(Path2), "%s%s", PreStr2, NewPlayerModelPath[num]);
		    TrimString(Path2);
			if(FileExists(Path2, true))
			    SetEntityModel(Client, Path2);
			
			DataPack pack = new DataPack();
		    pack.WriteCell(Client);
			pack.WriteCell(num);
			CreateTimer(0.2, Timer_ChangePlayerModel, pack);
		}	
        iEntPlayerModelList[Client] = num;		
	}
	
}


//设置新人物函数
public Action:Timer_ChangePlayerModel(Handle timer, DataPack pack)
{
	pack.Reset(); 
	int client = pack.ReadCell();
	int num = pack.ReadCell();
	CloseHandle(pack);
	iEntPlayerModelList[client] = num;
}


//监听选择人物的控制台命令的响应函数
public Action:OnJoinClass(client, const String:command[], argc)
{
	iEntPlayerModelList[client] = -1;	    
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(isEnabled == false)
	    return;
	
	if(IsClient(client, true) && !IsFakeClient(client) && iEntPlayerModelList[client] > -1)
	{
		int myPlayer = -1;
		myPlayer = iEntPlayerModelList[client];
		
		decl String:PreStr2[] = "models/player/";
		decl String:Path2[64];
		Format(Path2, sizeof(Path2), "%s%s", PreStr2, NewPlayerModelPath[myPlayer]);
		TrimString(Path2);
		if(FileExists(Path2, true))
			SetEntityModel(client, Path2);
	}

	
	//为警察bot随机选择新人物
	if(ctbotsnum > 0)
	{
		if(IsClient(client, true) && IsFakeClient(client))
		{
			if(RoundNum == 1 && GetClientTeam(client) == CS_TEAM_CT && iEntCTBotsModelList[client] == -1)
			{
				int IsUseNewPlayerModel = GetRandomInt(1,RoundToCeil((ctbotsnum + 4) * 1.5));
				//PrintToChatAll("提示1：警察随机数：%d", IsUseNewPlayerModel);
			    if(IsUseNewPlayerModel < (ctbotsnum + 1))
			    {
				    int TypesOfNewPlayerModel = GetRandomInt(0, ctbotsnum - 1);    //从新人物中随机选择一种
				    decl String:PreStr3[] = "models/player/";
		            decl String:Path3[64];
		            Format(Path3, sizeof(Path3), "%s%s", PreStr3, NewCTBotsModelPath[TypesOfNewPlayerModel]);
		            TrimString(Path3);
					if(FileExists(Path3, true))
					{
						SetEntityModel(client, Path3);
						iEntCTBotsModelList[client] = TypesOfNewPlayerModel;
					}
			            
			    }
			}
			if(RoundNum > 1 && GetClientTeam(client) == CS_TEAM_CT && iEntCTBotsModelList[client] > -1)
			{
				//PrintToChatAll("提示2：警察，索引：%d", iEntCTBotsModelList[client]);
				int tempNum = iEntCTBotsModelList[client];
				decl String:PreStr3[] = "models/player/";
				decl String:Path3[64];
				Format(Path3, sizeof(Path3), "%s%s", PreStr3, NewCTBotsModelPath[tempNum]);
				TrimString(Path3);
				if(FileExists(Path3, true))
				{
					SetEntityModel(client, Path3);
				}
		    }
		}
	}
	//为匪徒bot随机选择新人物
	if(terbotsnum > 0)
	{
		if(IsClient(client, true) && IsFakeClient(client))
		{
			if(RoundNum == 1 && GetClientTeam(client) == CS_TEAM_T && iEntTERBotsModelList[client] == -1)
			{
                int IsUseNewPlayerModel = GetRandomInt(1,RoundToCeil((terbotsnum + 4) * 1.5));
				//PrintToChatAll("提示1：匪徒随机数：%d", IsUseNewPlayerModel);
			    if(IsUseNewPlayerModel < (terbotsnum + 1))
			    {			
				    int TypesOfNewPlayerModel = GetRandomInt(0, terbotsnum - 1);    //从新人物中随机选择一种
				    decl String:PreStr4[] = "models/player/";
		            decl String:Path4[64];
		            Format(Path4, sizeof(Path4), "%s%s", PreStr4, NewTERBotsModelPath[TypesOfNewPlayerModel]);
		            TrimString(Path4);
					if(FileExists(Path4, true))
					{
						SetEntityModel(client, Path4);
						iEntTERBotsModelList[client] = TypesOfNewPlayerModel;
					}
			            
			    }
			}
			if(RoundNum > 1 && GetClientTeam(client) == CS_TEAM_T && iEntTERBotsModelList[client] > -1)
			{
				//PrintToChatAll("提示2：匪徒，索引：%d", iEntTERBotsModelList[client]);
				int tempNum = iEntTERBotsModelList[client];
				decl String:PreStr4[] = "models/player/";
				decl String:Path4[64];
				Format(Path4, sizeof(Path4), "%s%s", PreStr4, NewTERBotsModelPath[tempNum]);
				TrimString(Path4);
				if(FileExists(Path4, true))
				{
					SetEntityModel(client, Path4);
				}
		    }
		}
	}
}


public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if(isEnabled == false)
	    return;
	RoundNum++;
	//PrintToChatAll("提示：回合数：%d", RoundNum);
}

