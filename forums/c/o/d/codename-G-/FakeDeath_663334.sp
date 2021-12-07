/////////////////////////////////////////////////////////////////////
//
// インクルード
//
/////////////////////////////////////////////////////////////////////
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include "rmf/tf2_codes"
#include "rmf/tf2_events"


/////////////////////////////////////////////////////////////////////
//
// 定数
//
/////////////////////////////////////////////////////////////////////
#define PL_NAME "Fake Death"
#define PL_DESC "Fake Death"
#define PL_VERSION "1.1.2"

// スパイ
#define SOUND_EMPTY "misc/talk.wav"
#define SOUND_DISSOLVE "player/pl_impact_flare3.wav"

/////////////////////////////////////////////////////////////////////
//
// MOD情報
//
/////////////////////////////////////////////////////////////////////
public Plugin:myinfo = 
{
	name = PL_NAME,
	author = "RIKUSYO",
	description = PL_DESC,
	version = PL_VERSION,
	url = "http://ameblo.jp/rikusyo/"
}


/////////////////////////////////////////////////////////////////////
//
// グローバル変数
//
/////////////////////////////////////////////////////////////////////

new Handle:g_UseCloakMeter = INVALID_HANDLE;				// ConVarフェイクデスクロークメーター使用量
new Handle:g_WaitTime = INVALID_HANDLE;						// ConVarフェイクデス次の死体を出すまでの間隔
new Handle:g_Dissolve = INVALID_HANDLE;						// ConVarフェイクデス偽死体消去するかどうか
new Handle:g_DissolveTime = INVALID_HANDLE;					// ConVarフェイクデス偽死体消去までの時間
new Handle:g_DissolveType = INVALID_HANDLE;					// ConVarフェイクデス偽死体消去タイプ
new Handle:g_DissolveUncloak = INVALID_HANDLE;				// ConVarフェイクデス透明解除で偽死体消去するかどうか

new bool:g_PlayerGib[MAXPLAYERS+1];							// 爆殺？
new Handle:g_NextBody[MAXPLAYERS+1] = INVALID_HANDLE;		// 次の死体までのタイマー
new Handle:g_HitClear[MAXPLAYERS+1] = INVALID_HANDLE;   	// ヒットデータのタイマー
new Handle:g_DissolveFakeBody[MAXPLAYERS+1] = INVALID_HANDLE;	// 偽死体消去までの時間
new g_Ragdoll[MAXPLAYERS+1] = -1;   						// 偽死体

new String:g_PainVoice[5][32];								// 死にボイス

/////////////////////////////////////////////////////////////////////
//
// イベント発動
//
/////////////////////////////////////////////////////////////////////
stock Action:Event_FiredUser(Handle:event, const String:name[], any:client=0)
{
	
	// プラグイン開始
	if(StrEqual(name, EVENT_PLUGIN_START))
	{
		// 言語ファイル読込
		LoadTranslations("fakedeath.phrases");

		// コマンド作成
		CreateConVar("sm_rmf_tf_fakedeath", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_fakedeath","1","Fake Death Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);
		
		// スパイ
		g_UseCloakMeter = CreateConVar("sm_rmf_fake_cloak_use","10","Cloak Meter required for fake death(0-100)");
		g_WaitTime = CreateConVar("sm_rmf_fake_wait","3.0","Time before can show the next body(0.0-10.0)");
		g_Dissolve = CreateConVar("sm_rmf_fake_dissolve","1","Last body dissolve Enable/Disable (0 = disabled | 1 = enabled)");
		g_DissolveTime = CreateConVar("sm_rmf_fake_dissolve_time","8.0","Time before dissolve the last fake body(1.0-50.0)");
		g_DissolveType = CreateConVar("sm_rmf_fake_dissolve_type","1","Fake body dissolve type(0-3)");
		g_DissolveUncloak = CreateConVar("sm_rmf_fake_dissolve_uncloak","1","Last body dissolve when uncloak Enable/Disable (0 = disabled | 1 = enabled)");

		HookConVarChange(g_UseCloakMeter, ConVarChange_UseCloakMeter);
		HookConVarChange(g_WaitTime, ConVarChange_WaitTime);
		HookConVarChange(g_Dissolve, ConVarChange_Dissolve);
		HookConVarChange(g_DissolveTime, ConVarChange_DissolveTime);
		HookConVarChange(g_DissolveType, ConVarChange_DissolveType);
		HookConVarChange(g_DissolveUncloak, ConVarChange_g_DissolveUncloak);

		// ボイス
		g_PainVoice[0] = "vo/spy_painsevere01.wav";
		g_PainVoice[1] = "vo/spy_painsevere02.wav";
		g_PainVoice[2] = "vo/spy_painsevere03.wav";
		g_PainVoice[3] = "vo/spy_painsevere04.wav";
		g_PainVoice[4] = "vo/spy_painsevere05.wav";
	}
	

	// マップ開始
	if(StrEqual(name, EVENT_MAP_START))
	{
		// モデル読込
		PrecacheModel("models/player/hwm/spy.mdl", true);
		
		// スパイ
		PrecacheSound(SOUND_EMPTY, true);
		PrecacheSound(SOUND_DISSOLVE, true);
		
		// 死に声
		for (new i = 1; i <= 4; i++)
		{
			PrecacheSound(g_PainVoice[i], true);
		}
	}

	
	// ゲームフレーム
	if(StrEqual(name, EVENT_GAME_FRAME))
	{
		new maxclients = GetMaxClients();
		for (new i = 1; i <= maxclients; i++)
		{
			FrameAction(i);
		}
	}
	
	// プレイヤーリセット
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		// 偽死体削除
		DissolveFakeBody(client);

		// バラバラフラグクリア
		g_PlayerGib[client] = false;

		// 次の死体タイマークリア
		if(g_NextBody[client] != INVALID_HANDLE)
		{
			KillTimer(g_NextBody[client]);
			g_NextBody[client] = INVALID_HANDLE;
		}
		
		// ヒットデータタイマークリア
		if(g_HitClear[client] != INVALID_HANDLE)
		{
			KillTimer(g_HitClear[client]);
			g_HitClear[client] = INVALID_HANDLE;
		}
		
		// 死体消去タイマークリア
		if(g_DissolveFakeBody[client] != INVALID_HANDLE)
		{
			KillTimer(g_DissolveFakeBody[client]);
			g_DissolveFakeBody[client] = INVALID_HANDLE;
		}
		
		// 説明文
		if( TF2_GetPlayerClass( client ) == TFClass_Spy)
		{
			Format(g_PlayerHintText[client][0], HintTextMaxSize , "%t", "HOWTO_TEXT_SPY");
			Format(g_PlayerHintText[client][1], HintTextMaxSize , "%t", "TIPS_TEXT_SPY", GetConVarInt(g_UseCloakMeter));
		}
	}
		

	// ダメージ
	if(StrEqual(name, EVENT_PLAYER_DAMAGE))
	{
		new client_victim = client;
		new client_attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

		new TFClassType:class = TF2_GetPlayerClass(client_victim);
		if (client_attacker > 0 && class == TFClass_Spy)
		{
			new String:classname[64];
			TF2_GetCurrentWeaponClass(client_attacker, classname, 64);

			if( StrEqual(classname, "CTFRocketLauncher") || StrEqual(classname, "CTFGrenadeLauncher") || StrEqual(classname, "CTFPipebombLauncher") )
			{
				g_PlayerGib[client_victim] = true;
								
				if(g_HitClear[client_victim] != INVALID_HANDLE)
				{
					KillTimer(g_HitClear[client_victim]);
					g_HitClear[client_victim] = CreateTimer(0.65, Timer_HitClearTimer, client_victim);
				}
				else
				{
					g_HitClear[client_victim] = CreateTimer(0.65, Timer_HitClearTimer, client_victim);
				}

			}
			else
			{
				g_PlayerGib[client_victim] = false;
			}
		}
	}

	// 死亡
	if(StrEqual(name, EVENT_PLAYER_DEATH))
	{
		// 死んだら偽の死体消去
		if( TF2_GetPlayerClass( client ) == TFClass_Spy )
		{
			DissolveFakeBody(client);
		}
	}
	return Plugin_Continue;
}



/////////////////////////////////////////////////////////////////////
//
// クロークメーター使用量の設定
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_UseCloakMeter(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0.0～100.0まで
	if (StringToInt(newValue) < 0 || StringToInt(newValue) > 100)
	{
		SetConVarInt(convar, StringToInt(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0 and 100");
	}
}

/////////////////////////////////////////////////////////////////////
//
// 次の死体を出せるまでの待ち時間の設定
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_WaitTime(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0.0～10.0まで
	if (StringToFloat(newValue) < 0.0 || StringToFloat(newValue) > 10.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0.0 and 10.0");
	}
}
/////////////////////////////////////////////////////////////////////
//
// 死体消去する？
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_Dissolve(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0か1
	if (StringToInt(newValue) != 0 && StringToInt(newValue) != 1)
	{
		SetConVarInt(convar, StringToInt(oldValue), false, false);
		PrintToServer("Warning: Value has to be 0 or 1");
	}
}
/////////////////////////////////////////////////////////////////////
//
// 前の死体を消すまでの時間
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_DissolveTime(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 1.0～10.0まで
	if (StringToFloat(newValue) < 1.0 || StringToFloat(newValue) > 50.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 1.0 and 50.0");
	}
}

/////////////////////////////////////////////////////////////////////
//
// 消去タイプ
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_DissolveType(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0～3まで
	if (StringToInt(newValue) < 0 || StringToInt(newValue) > 3)
	{
		SetConVarInt(convar, StringToInt(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0 and 3");
	}
}
/////////////////////////////////////////////////////////////////////
//
// 透明解除で死体消去する？
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_g_DissolveUncloak(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0か1
	if (StringToInt(newValue) != 0 && StringToInt(newValue) != 1)
	{
		SetConVarInt(convar, StringToInt(oldValue), false, false);
		PrintToServer("Warning: Value has to be 0 or 1");
	}
}



/////////////////////////////////////////////////////////////////////
//
// ゲームフレーム
//
/////////////////////////////////////////////////////////////////////
stock FrameAction(any:client)
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// スパイ＆フェイクデスON
		if( TF2_GetPlayerClass( client ) == TFClass_Spy )
		{
			if( g_PlayerButtonDown[client] == INVALID_HANDLE )
			{
				// フェイクデス
				FakeDeath(client);
			}

			// 透明解除で死体消去？
			if(GetConVarBool(g_DissolveUncloak))
			{
				if(!TF2_IsPlayerCloaked(client))
				{
					DissolveFakeBody(client);
				}
			}
		}		
		

	}
		
}

/////////////////////////////////////////////////////////////////////
//
// フェイクデス
//
/////////////////////////////////////////////////////////////////////
public FakeDeath(any:client)
{
	// 透明解除したらリセット
	if(!TF2_IsPlayerCloaked(client))
	{
		// 肉片リセット
		g_PlayerGib[client] = false;
	}
	
	// アタック1
	if (GetClientButtons(client) & IN_ATTACK)
	{
		// 連続押し防止？
		g_PlayerButtonDown[client] = CreateTimer(0.5, Timer_ButtonUp, client);
	
		// 偽物の死体さくせい
		SpawnFakeBody(client);
		
		// 肉片リセット
		g_PlayerGib[client] = false;
	}

}

/////////////////////////////////////////////////////////////////////
//
// 偽の死体削除
//
/////////////////////////////////////////////////////////////////////
public DissolveFakeBody(client)
{
	if(!GetConVarBool(g_Dissolve))
		return;
	
	// 以前の偽死体を消す
	if(g_Ragdoll[client] != -1)
	{
		if( IsValidEntity(g_Ragdoll[client]) )
		{
			// 消えるサウンド
			EmitSoundToAll(SOUND_DISSOLVE, g_Ragdoll[client], _, _, SND_CHANGEPITCH, 0.6, 80);
			
			new String:dname[32], String:dtype[32];
			Format(dname, sizeof(dname), "dis_%d", client);
			Format(dtype, sizeof(dtype), "%d", GetConVarInt(g_DissolveType));

			new ent = CreateEntityByName("env_entity_dissolver");
			if (ent>0)
			{
				DispatchKeyValue(g_Ragdoll[client], "targetname", dname);
				DispatchKeyValue(ent, "dissolvetype", dtype);
				DispatchKeyValue(ent, "target", dname);
				AcceptEntityInput(ent, "Dissolve");
				AcceptEntityInput(ent, "kill");
			}
			g_Ragdoll[client] = -1;
		}
	}	
}

/////////////////////////////////////////////////////////////////////
//
// 偽の死体作成
//
/////////////////////////////////////////////////////////////////////
public SpawnFakeBody(client)
{
	new Float:PlayerPosition[3];
	//new Float:PlayerForce[3];
		
	if(TF2_IsPlayerCloaked(client))
	{
		// メーター使用量
		new UseMeter = GetConVarInt(g_UseCloakMeter);
		new NowMeter = TF2_GetPlayerCloakMeter(client);
		// 次に押せるまでの時間
		new Float:WaitTime = GetConVarFloat(g_WaitTime);
	
		if( NowMeter > UseMeter  && g_NextBody[client] == INVALID_HANDLE)
		{
			new FakeBody = CreateEntityByName("tf_ragdoll");

			// 偽死体削除
			DissolveFakeBody(client);
			
			if (DispatchSpawn(FakeBody))
			{
				// 発生位置
				GetClientAbsOrigin(client, PlayerPosition);
				new offset = FindSendPropOffs("CTFRagdoll", "m_vecRagdollOrigin");
				SetEntDataVector(FakeBody, offset, PlayerPosition);
				
				// 死体のクラスはスパイ
				offset = FindSendPropOffs("CTFRagdoll", "m_iClass");
				SetEntData(FakeBody, offset, 8);

				// 燃えている
				if(TF2_IsPlayerOnFire(client))
				{
					offset = FindSendPropOffs("CTFRagdoll", "m_bBurning");
					SetEntData(FakeBody, offset, 1);
					
				}
				if(g_PlayerGib[client])
				{
					offset = FindSendPropOffs("CTFRagdoll", "m_bGib");
					SetEntData(FakeBody, offset, 1);
					new gibHead = CreateEntityByName("raggib");
					if(DispatchSpawn(FakeBody))
					{
						new offset2 = FindSendPropOffs("CBaseAnimating", "m_vecOrigin");
						SetEntDataVector(gibHead, offset2, PlayerPosition);
					}
					
				}
				g_PlayerGib[client] = false;

				offset = FindSendPropOffs("CTFRagdoll", "m_iPlayerIndex");
				SetEntData(FakeBody, offset, client);
				
				// 死体のチームカラー
				new team = GetClientTeam(client);
				offset = FindSendPropOffs("CTFRagdoll", "m_iTeam");
				SetEntData(FakeBody, offset, team);
				
				EmitSoundToAll(g_PainVoice[GetRandomInt(0, 4)], FakeBody, _, _, _, 1.0);
				
				NowMeter = NowMeter - UseMeter;
				TF2_SetPlayerCloakMeter(client,NowMeter);
				g_NextBody[client] = CreateTimer(WaitTime, Timer_NextBodyTimer, client);

				// 発生させた死体を保存&消去タイマー設定
				new Float:DissolveTime = GetConVarFloat(g_DissolveTime);

				g_Ragdoll[client] = FakeBody;
				if(g_DissolveFakeBody[client] != INVALID_HANDLE)
				{
					KillTimer(g_DissolveFakeBody[client]);
					g_DissolveFakeBody[client] = INVALID_HANDLE;
				}
				g_DissolveFakeBody[client] = CreateTimer(DissolveTime, Timer_DissolveFakeBodyTimer, client);
				
				return;
			}			
		}
		
		EmitSoundToClient(client, SOUND_EMPTY, _, _, _, _, 0.55);
	}
	

}
/////////////////////////////////////////////////////////////////////
//
// 偽死体消去タイマー
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_DissolveFakeBodyTimer(Handle:timer, any:client)
{
	g_DissolveFakeBody[client] = INVALID_HANDLE;
	// 偽死体削除
	DissolveFakeBody(client);
}

/////////////////////////////////////////////////////////////////////
//
// 次の死体
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_NextBodyTimer(Handle:timer, any:client)
{
	g_NextBody[client] = INVALID_HANDLE;
}

/////////////////////////////////////////////////////////////////////
//
// ヒットをクリア
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_HitClearTimer(Handle:timer, any:client)
{
	// 肉片リセット
	g_PlayerGib[client] = false;
	g_HitClear[client] = INVALID_HANDLE;
}


