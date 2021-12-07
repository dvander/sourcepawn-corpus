#include <sourcemod>
#include <sdktools>
#include <clients> 
#include <events> 
#include <sdkhooks>
#include <logging>

#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#define AUTODIFF_VERSION "3.3"
#define CVAR_FLAGS			ADMFLAG_GENERIC


public Plugin myinfo = 
{
	name = "Diffculity Auto Changer",
	author = "quewn",
	description = "自动改难度，可开关手动控制",
	version = AUTODIFF_VERSION,
	url = ""
}
//全局

ConVar g_hCvar_Is_enabled, g_CvarEz_CLcount, g_CvarNom_Clcount, g_CvarHd_Clcount, g_Cvarxpt_Clcount, g_hCvar_Is_DiffStrict, g_Cvar_DeafultDiff;
bool Is_AutoDiffEnabled, g_Cvar_Is_Strict, g_Cvar_log; //开关 
int g_iCvarEz_CLcount, g_iCvarNom_Clcount, g_iCvarHd_Clcount, g_iCvarxpt_Clcount, deafult_diffculty_level, max_Clcount, min_Clcount;
//bool hasMin, float min, bool hasMax, float max

public void OnPluginStart()
{
	HookEvent("player_team", ClNumCg);
	GetCvars();
	
	CreateConVar("l4d2_AUTODIFF_VERSION", AUTODIFF_VERSION, "version",FCVAR_SPONLY|FCVAR_NOTIFY); //测试cfg生成
	
	RegAdminCmd("sm_autodiff", Cmd_DiffAutoSwitch, CVAR_FLAGS);
	AutoExecConfig(true,				"Auto_Diffculty");	
	
	g_hCvar_Is_enabled = CreateConVar("diff_deafult_status" , "1" , "Deafult Switch", CVAR_FLAGS, 1, 0, 1, 1 );
	g_hCvar_Is_DiffStrict = CreateConVar("diff_Strict_Mode" , "0" , "Switch Between Trigger Mode", CVAR_FLAGS, 1, 0, 1, 1 );
		
	g_CvarEz_CLcount  = CreateConVar("diff_ez_clinet_counts" , "2" , "hao many players for eazy", CVAR_FLAGS, 1, 0, 0, 0 ); //float?
	g_CvarNom_Clcount = CreateConVar("diff_nom_clinet_counts" , "4" , "hao many players for normal", CVAR_FLAGS, 1, 0, 0, 0 );
	g_CvarHd_Clcount  = CreateConVar("diff_hd_clinet_counts" , "6" , "hao many players for hard", CVAR_FLAGS, 1, 0, 0, 0 );
	g_Cvarxpt_Clcount = CreateConVar("diff_xpt_clinet_counts" , "8" , "hao many players for impossible", CVAR_FLAGS, 1, 0, 0, 0 );
	
	
	g_Cvar_DeafultDiff = CreateConVar("deafult_diffculty_level" , "1" , "deafult difficulity 1 for normal ", 1, 0, 1, 3 );
	g_Cvar_log = CreateConVar("log_switcher" , "0" , "log switch", CVAR_FLAGS, 1, 0, 1, 1 );
}

// ====================================================================================================
//					CVARS
// ====================================================================================================
void GetCvars()
{
	g_iCvarEz_CLcount = g_CvarEz_CLcount.IntValue;
	g_iCvarNom_Clcount = g_CvarNom_Clcount.IntValue;
	g_iCvarHd_Clcount = g_CvarHd_Clcount.IntValue;
	g_iCvarxpt_Clcount = g_Cvarxpt_Clcount.IntValue;
	
	max_Clcount = GetMaxCl(g_iCvarEz_CLcount, g_iCvarNom_Clcount, g_iCvarHd_Clcount, g_iCvarxpt_Clcount);
	min_Clcount = GetMinCl(g_iCvarEz_CLcount, g_iCvarNom_Clcount, g_iCvarHd_Clcount, g_iCvarxpt_Clcount);
	
//	g_Cvar_Is_Strict = g_hCvar_Is_DiffStrict.BoolValue;
//	g_Cvar_Is_enabled = g_hCvar_Is_enabled.BoolValue;
}

int GetMaxCl(int a, int b, int c, int d) //弱鸡写法 见笑
{
	int max;
	if(a >= b){
		a = max;
	}else if(b >= a){
		b = max;
	}else if(c >= max){
		c = max;
	}else if(d >= max){
		d = max;
	}
	return max;
}

int GetMinCl(int a, int b, int c, int d)
{
	int min;
	if(a <= b){
		a = min;
	}else if(b <= a){
		b = min;
	}else if(c <= min){
		c = min;
	}else if(d <= min){
		d = min;
	}
	return min;
}


public void OnConfigsExecuted()
{
	GetCvars();
}

public void OnMapStart()
{
	GetCvars();
}


public Action Cmd_DiffAutoSwitch(int iClient, int args) //指令开关
{
	GetCvars();
	if(Is_AutoDiffEnabled != 0 )
	{
		Is_AutoDiffEnabled = 0;
		PrintToChat(iClient, "AutoDiffer now OFF");
		if(g_Cvar_log){LogAction(iClient, -1, "\"%L\" turned off AutoDiffer", iClient);}
	}
	else
	{
		Is_AutoDiffEnabled = 1;
		PrintToChat(iClient, "AutoDiffer now ON");
		if(g_Cvar_log){LogAction(iClient, -1, "\"%L\"  turned on AutoDiffer", iClient);}
	}
	return Plugin_Handled;
}


public Action ClNumCg(Event event, const char[] name, bool dontBroadcast) //人数变化启动这块代码块 1开
{
//		int client = GetClientOfUserId(event.GetInt("userid"));
	int RealPlayer_count;
	for (int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i))
			++RealPlayer_count;
	if(g_Cvar_log){LogAction(-1 , -1, "\"%L\"player on court %i", RealPlayer_count);}
	if(Is_AutoDiffEnabled != 0 ){
		diff_change(player_numdef(RealPlayer_count, g_iCvarEz_CLcount, g_iCvarNom_Clcount, g_iCvarHd_Clcount, g_iCvarxpt_Clcount, g_Cvar_DeafultDiff));
		return Plugin_Handled;
	}else{
		return Plugin_Handled;
	}
}


public int player_numdef(int clcounts, int ez, int nom, int hd, int xpt, int deafultdiff)
{
	
	if (g_hCvar_Is_DiffStrict)
	{
		if (clcounts <= ez){
			return 0;
		} else if(clcounts > ez && clcounts <= nom){
			return 1;
		} else if(clcounts > nom && clcounts <= hd){
			return 2;
		} else if(clcounts > hd && clcounts < xpt){
			return 3;
		} else if(clcounts >= xpt){
			return 3;
		} else{
			return deafultdiff;
		}
	}else{
		
		
		if (clcounts = ez){
			return 0;
		} else if(clcounts = nom){
			return 1;
		} else if(clcounts = hd){
			return 2;
		} else if(clcounts = xpt){
			return 3;
		} else if(clcounts <= min_Clcount || clcounts >= max_Clcount){
			return deafultdiff;
		} else{
			return Plugin_Handled;
		}
	}
}

//排序函数
// void sort(int *p,int len)
// {
    // for (int i = 0;i < len;i ++)
    // {
     //  第二层循环，随着外层循环次数的递增而递减，因为每排序一次，就把相对大的数据往后放一位，就不需要对该数据进行再次排序了
        // for(int j = 0;j < len -i -1;j ++)
        // {
            // if (p[j] > p[j + 1])
            // {
              // 数据调换
                // int temp = p[j];
                // p[j] = p[j + 1];
                // p[j + 1] = temp;
            // }
        // }
    // }
// }

// void sortdiff(int a, int b, int c, int d)
// {
 ////   要排序的数组
    // int arr[4] = {a, b, c, d};

 //  sort(arr,SIZE);

    // return *arr;
// }

public int diff_change(int param)
{
		char difficulty[32];
	GetConVarString(FindConVar("z_difficulty"), difficulty, sizeof(difficulty));

	switch (param)
	{
		case 0:
		{
			if (!StrEqual(difficulty, "Easy", false))
			{
				SetConVarString(FindConVar("z_difficulty"), "Easy");
			}
		}
		case 1:
		{
			if (!StrEqual(difficulty, "Normal", false))
			{
				SetConVarString(FindConVar("z_difficulty"), "Normal");
			}
		}
		case 2:
		{
			if (!StrEqual(difficulty, "Hard", false))
			{
				SetConVarString(FindConVar("z_difficulty"), "Hard");
			}
		}
		case 3:
		{
			if (!StrEqual(difficulty, "Impossible", false))
			{
				SetConVarString(FindConVar("z_difficulty"), "Impossible");
			}
	
		}

	}
}

//

