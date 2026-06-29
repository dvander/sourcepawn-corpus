/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2009/09/05 - 0.0.1
// ・サーバーに入って最初の復活の際、画面が観戦モードのようになるのを修正

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
#define PL_NAME "Spy Jutsu"
#define PL_DESC "Spy Jutsu"
#define PL_VERSION "0.0.1"
#define PL_TRANSLATION "spyjutsu.phrases"

#define MDL_DISGUISE "models/buildables/sentry3.mdl"

#define SOUND_SPAWN_Disguise "player/pl_impact_stun.wav"
#define SOUND_CHARGE_POWER "ui/item_acquired.wav"
#define SOUND_NO_POWER "weapons/medigun_no_target.wav"

#define EFFECT_Disguise_SPAWN_SMOKE "Explosion_Smoke_1"
#define EFFECT_Disguise_SPAWN_FLASH "Explosion_Flash_1"

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
new Handle:g_ChargeTime = INVALID_HANDLE;						// ConVarチャージ時間

new g_DisguiseModel[MAXPLAYERS+1] = -1;			// モデル
new g_IsDisguiseActive[MAXPLAYERS+1] = -1;		// 樽の中？
new Handle:g_HideVoicehTimer[MAXPLAYERS+1] = INVALID_HANDLE;	// ボイスタイマー
new Handle:g_PowerChargeTimer[MAXPLAYERS+1] = INVALID_HANDLE;	// パワーチャージタイマー
new String:SOUND_START_VOICE[5][64];							// 隠れ開始ボイス
new String:SOUND_HIDE_VOICE[5][64];								// 隠れボイス
new String:SOUND_UNHIDE_VOICE[5][64];							// 登場ボイス
new HideVoiceCount = 0;											// ボイスカウント
new g_NowHealth[MAXPLAYERS+1] = 0; 								// 現在のヘルス
new Float:g_NextUseTime[MAXPLAYERS+1] = 0.0; 					// 次に使えるようになるまでの時間

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
		LoadTranslations(PL_TRANSLATION);

		// コマンド作成
		CreateConVar("sm_rmf_tf_spyjutsu", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_spyjutsu","1","Enable/Disable (0 = disabled | 1 = enabled)");
		
		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);
		
		g_ChargeTime = CreateConVar("sm_rmf_spyjutsu_charge_time","0.0", "Power charge time (1.0-60.0)");
		HookConVarChange(g_ChargeTime, ConVarChange_ChargeTime);
		
		// 回復棚にタッチ
//		HookEntityOutput("func_regenerate",  "OnStartTouch",    EntityOutput_StartTouch);
	
		// アビリティクラス設定
		CreateConVar("sm_rmf_spyjutsu_class", "1", "Ability class");
		
		// 隠れボイス
		SOUND_HIDE_VOICE[0] = "weapons/sentry_scan3.wav";
		SOUND_HIDE_VOICE[1] = "weapons/sentry_scan3.wav";
		SOUND_HIDE_VOICE[2] = "weapons/sentry_scan3.wav";
		SOUND_HIDE_VOICE[3] = "weapons/sentry_scan.wav3";
		SOUND_HIDE_VOICE[4] = "weapons/sentry_scan3.wav";
		// 登場ボイス
		SOUND_UNHIDE_VOICE[0] = "vo/spy_laughlong01.wav";
		SOUND_UNHIDE_VOICE[1] = "vo/spy_laughhappy01.wav";
		SOUND_UNHIDE_VOICE[2] = "vo/spy_laughhappy02.wav";
		SOUND_UNHIDE_VOICE[3] = "vo/spy_laughhappy03.wav";
		SOUND_UNHIDE_VOICE[4] = "vo/spy_laughevil01.wav";
		// 隠れ開始ボイス
		SOUND_START_VOICE[0] = "weapons/sentry_finish.wav";
		SOUND_START_VOICE[1] = "weapons/sentry_finish.wav";
		SOUND_START_VOICE[2] = "weapons/sentry_finish.wav";
		SOUND_START_VOICE[3] = "weapons/sentry_finish.wav";
		SOUND_START_VOICE[4] = "weapons/sentry_finish.wav";

	}
	// プラグイン初期化
	if(StrEqual(name, EVENT_PLUGIN_INIT))
	{
		// 初期化が必要なもの
		new maxclients = GetMaxClients();
		for (new i = 1; i <= maxclients; i++)
		{
			// モデル削除
			DeleteModel(client)
			
			
		}
	}
	// プラグイン後始末
	if(StrEqual(name, EVENT_PLUGIN_FINAL))
	{
		// 初期化が必要なもの
		new maxclients = GetMaxClients();
		for (new i = 1; i <= maxclients; i++)
		{
			// モデル削除
			DeleteModel(client)
		}
	}
	
	// マップスタート
	if(StrEqual(name, EVENT_MAP_START))
	{
		// エフェクト先読み
		PrePlayParticle(EFFECT_Disguise_SPAWN_SMOKE);
		PrePlayParticle(EFFECT_Disguise_SPAWN_FLASH);

		// モデル読み込み
		PrecacheModel(MDL_DISGUISE, true);
		
		//サウンド読み込み
		PrecacheSound(SOUND_SPAWN_Disguise, true);
		PrecacheSound(SOUND_CHARGE_POWER, true);
		PrecacheSound(SOUND_NO_POWER, true);
		for( new i = 0; i < 5; i++)
		{
			PrecacheSound(SOUND_HIDE_VOICE[i], true);
			PrecacheSound(SOUND_UNHIDE_VOICE[i], true);
			PrecacheSound(SOUND_START_VOICE[i], true);
		}
		
		// 初期化が必要なもの
		new maxclients = GetMaxClients();
		for (new i = 1; i <= maxclients; i++)
		{
			// モデル削除
			DeleteModel(client)
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
		// 速度戻す
		TF2_SetPlayerDefaultSpeed(client);

		// 次に使えるまでの時間リセット
		g_NextUseTime[client] = 0.0;
		
		// ボイスタイマー停止
		if(g_HideVoicehTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_HideVoicehTimer[client]);
			g_HideVoicehTimer[client] = INVALID_HANDLE;
		}
		
		// パワーチャージタイマー停止
		if(g_PowerChargeTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_PowerChargeTimer[client]);
			g_PowerChargeTimer[client] = INVALID_HANDLE;
		}
		
		// ボイスカウントリセット
		HideVoiceCount = 0;
		
		// 現在のヘルス保存
		g_NowHealth[client] = GetClientHealth(client);
		
		// 見える
		SetPlayerRenderHide(client, false);

		// 視点を戻す
		//SetClientViewEntity(client, client);
		//SetEntProp(client, Prop_Send, "m_iObserverMode", 0);

		// モデル削除
		DeleteModel(client);
		
		
		// 説明文
		if( TF2_GetPlayerClass( client ) == TFClass_Spy)
		{
			Format(g_PlayerHintText[client][0], HintTextMaxSize , "%T", "DESCRIPTION_0_SPYJUTSU", client);
			Format(g_PlayerHintText[client][1], HintTextMaxSize , "%T", "DESCRIPTION_1_SPYJUTSU", client);
		}
		
	}
	

	// プレイヤーダメージ
	if(StrEqual(name, EVENT_PLAYER_DAMAGE))
	{
		// パイロ
		if( TF2_GetPlayerClass( client ) == TFClass_Spy )
		{
			// 樽の中に入っている
			if(g_IsDisguiseActive[client])
			{
				// 食らったダメージ取得
				new damage = g_NowHealth[client] - GetEventInt(event, "health");
				
				// 50以上のダメージを受けたら解除
				if( damage > 50 )
				{
					// ボイスタイマー停止
					if(g_HideVoicehTimer[client] != INVALID_HANDLE)
					{
						KillTimer(g_HideVoicehTimer[client]);
						g_HideVoicehTimer[client] = INVALID_HANDLE;
					}

					// 見える
					SetPlayerRenderHide(client, false);

					// 視点を戻す
					SetEntProp(client, Prop_Send, "m_iObserverMode", 0);

					// モデル削除
					DeleteModel(client);
					
					// 速度戻す
					TF2_SetPlayerDefaultSpeed(client);
		
					// 次に使用可能になるまでの時間設定
					g_NextUseTime[client] = GetGameTime() + GetConVarFloat(g_ChargeTime);
								
					// パワーチャージタイマー発動
					if(g_PowerChargeTimer[client] != INVALID_HANDLE)
					{
						KillTimer(g_PowerChargeTimer[client]);
						g_PowerChargeTimer[client] = INVALID_HANDLE;
					}
					g_PowerChargeTimer[client] = CreateTimer(GetConVarFloat(g_ChargeTime), Timer_PowerChargeTimer, client);
								
				}
			}
		}
	}	
	return Plugin_Continue;
}



/////////////////////////////////////////////////////////////////////
//
// フレームアクション
//
/////////////////////////////////////////////////////////////////////
public FrameAction(any:client)
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// パイロのみ
		if(TF2_GetPlayerClass(client) == TFClass_Spy && g_AbilityUnlock[client])
		{
			// 発動中なら終了チェック
			if( g_IsDisguiseActive[client] )
			{
				//AdjustCameraPos(client);
				// 終了チェック
				EndCheck(client);
			}
			
			// キーチェック
			if( CheckElapsedTime(client, 0.5) )
			{
				// 攻撃ボタン
				if ( GetClientButtons(client) & IN_ATTACK2 )
				{
					// キーを押した時間を保存
					SaveKeyTime(client);
					SPYJUTSU(client);
				}

			}
		}
	}
}
/////////////////////////////////////////////////////////////////////
//
// 樽出現
//
/////////////////////////////////////////////////////////////////////
stock SPYJUTSU(any:client)
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// 武器はバックバーナーのみ
		//new weaponIndex = GetPlayerWeaponSlot(client, 0);
		if(TF2_GetItemDefIndex( TF2_GetCurrentWeapon(client) ) == _:ITEM_WEAPON_PDA_DISGUISE )
		{
			// 発動していなかったら発動
			if( !g_IsDisguiseActive[client]  )
			{
				// まだ使えないならメッセージ
				if( g_NextUseTime[client] > GetGameTime() )
				{
					EmitSoundToClient(client, SOUND_NO_POWER, client, _, _, _, 1.0);
					PrintToChat(client, "\x05%T", "CANT_USE_SPYJUTSU", client, g_NextUseTime[client] - GetGameTime());
					return;
				}
				
				// しゃがんだ状態・地上・移動していない
				if( GetEntityFlags(client) & FL_DUCKING
					&& GetEntityFlags(client) & FL_ONGROUND
					&& !(GetEntityFlags(client) & FL_INWATER)
					&& TF2_GetPlayerSpeed(client) == 0.0
				)
				{
					// 発動エフェクト
					new Float:pos[3];
					new Float:ang[3];
					ang[0] = -90.0;
					pos[2] = -30.0;
					
					AttachParticle(client, EFFECT_Disguise_SPAWN_FLASH, 1.0, pos, ang);
					for(new i = 0; i < 10; i++)
					{
						pos[0] = GetRandomFloat(-5.0, 5.0);
						pos[1] = GetRandomFloat(-5.0, 5.0);
						AttachParticle(client, EFFECT_Disguise_SPAWN_SMOKE, 1.0, pos, ang);
					}
					
					// 画面を一瞬灰色に。
					ScreenFade(client, 50, 50, 50, 255, 100, IN);
					
					// 発動サウンド
					EmitSoundToAll(SOUND_SPAWN_Disguise, client, _, _, SND_CHANGEPITCH, 0.8, 50);
					EmitSoundToAll(SOUND_START_VOICE[GetRandomInt(0, 4)], client, _, _, _, 1.0);
					
					// 樽モデル作成
					g_DisguiseModel[client] = CreateEntityByName("prop_dynamic");
					if (IsValidEdict(g_DisguiseModel[client]))
					{
						new String:tName[32];
						GetEntPropString(client, Prop_Data, "m_iName", tName, sizeof(tName));
						DispatchKeyValue(g_DisguiseModel[client], "targetname", "spy_Disguise");
						DispatchKeyValue(g_DisguiseModel[client], "parentname", tName);
						SetEntityModel(g_DisguiseModel[client], MDL_DISGUISE);
						DispatchSpawn(g_DisguiseModel[client]);
						if(GetClientTeam(client) == 2)
						{
							SetVariantInt(1);
							AcceptEntityInput(g_DisguiseModel[client], "Skin");
						}
						
						SetVariantInt(99999);
						AcceptEntityInput(g_DisguiseModel[client], "SetHealth");	
						// モデルをプレイヤーの位置に移動
						new Float:Pos[3];
						GetClientAbsOrigin(client, Pos);
						Pos[2] -=30;
						TeleportEntity(g_DisguiseModel[client], Pos, NULL_VECTOR, NULL_VECTOR);
						
				    }	
					
					// プレイヤーを見えなくする
					SetPlayerRenderHide(client, true);

					// 視点が変わらないよう前の死体を消す
					new body = -1;
					while ((body = FindEntityByClassname(body, "tf_ragdoll")) != -1)
					{
						//PrintToChat(client, "%d %d",client, GetEntProp(body, Prop_Send, "m_iPlayerIndex"));
						new iOwner = GetEntProp(body, Prop_Send, "m_iPlayerIndex");
						if(iOwner == client)
						{
							AcceptEntityInput(body, "Kill");
						}
					}

					// 三人称視点
					SetEntPropEnt(client, Prop_Data, "m_hObserverTarget", client);
					SetEntProp(client, Prop_Data, "m_iObserverMode", 1);
				
					// ボイスタイマー発動
					if(g_HideVoicehTimer[client] != INVALID_HANDLE)
					{
						KillTimer(g_HideVoicehTimer[client]);
						g_HideVoicehTimer[client] = INVALID_HANDLE;
					}
					g_HideVoicehTimer[client] = CreateTimer(3.5, Timer_HideVoiceTimer, client, TIMER_REPEAT);
					
					// ボイスカウントリセット
					HideVoiceCount = 0;

					// 現在のヘルスを保存
					g_NowHealth[client] = GetClientHealth(client);

					// 樽の中に入った
					g_IsDisguiseActive[client] = true;
				}
			}
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// 隠れさせる(見えなくする)
//
/////////////////////////////////////////////////////////////////////
stock SetPlayerRenderHide(any:client, bool:hide)
{
	// 透明にする
	if( hide )
	{
		// プレイヤー
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 0);
		
		// 武器
		for(new i = 0; i < 3; i++)
		{
			new weaponIndex = GetPlayerWeaponSlot(client, i);
			if( weaponIndex != -1 )
			{
				SetEntityRenderMode(weaponIndex, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weaponIndex, 255, 255, 255, 0);
			}
		}	
		
		// 帽子
		new hat = -1;
		while ((hat = FindEntityByClassname(hat, "tf_wearable_item")) != -1)
		{
			new iOwner = GetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity");
			if(iOwner == client)
			{
				SetEntityRenderMode(hat, RENDER_TRANSCOLOR);
				SetEntityRenderColor(hat, 255, 255, 255, 0);
			}
		}
	}
	else
	{
		// プレイヤー
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		
		// 武器
		for(new i = 0; i < 3; i++)
		{
			new weaponIndex = GetPlayerWeaponSlot(client, i);
			if( weaponIndex != -1 )
			{
				SetEntityRenderMode(weaponIndex, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weaponIndex, 255, 255, 255, 255);
			}
		}		
		
		// 帽子
		new hat = -1;
		while ((hat = FindEntityByClassname(hat, "tf_wearable_item")) != -1)
		{
			new iOwner = GetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity");
			if(iOwner == client)
			{
				SetEntityRenderMode(hat, RENDER_TRANSCOLOR);
				SetEntityRenderColor(hat, 255, 255, 255, 255);
			}
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// ボイスタイマー
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_HideVoiceTimer(Handle:timer, any:client)
{
	// 発動中ならチェック
	if(g_IsDisguiseActive[client])
	{
		if( IsClientInGame(client) && IsPlayerAlive(client) )
		{
			EmitSoundToAll(SOUND_HIDE_VOICE[HideVoiceCount], client, _, _, _, 1.0);
			HideVoiceCount++;
			if(HideVoiceCount > 4)
			{
				HideVoiceCount = 0;
			}
			
		}
	}
	else
	{
		// ボイスタイマー削除
		if(g_HideVoicehTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_HideVoicehTimer[client]);
			g_HideVoicehTimer[client] = INVALID_HANDLE;
		}		
	}

}

/////////////////////////////////////////////////////////////////////
//
// 発動終了チェック
//
/////////////////////////////////////////////////////////////////////
stock EndCheck(any:client)
{
	// 移動・攻撃または立つ・地上以外は解除
	if( GetClientButtons(client) & IN_ATTACK 
		|| GetEntityFlags(client) & FL_INWATER
	) 
	{
		// ボイスタイマー停止
		if(g_HideVoicehTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_HideVoicehTimer[client]);
			g_HideVoicehTimer[client] = INVALID_HANDLE;
		}

		// プレイヤーが解除したならボイス出す
		if( IsPlayerAlive(client) && GetEntityFlags(client) & FL_ONGROUND && !TF2_IsPlayerTaunt(client))
		{
			EmitSoundToAll(SOUND_UNHIDE_VOICE[GetRandomInt(0, 4)], client, _, _, _, 1.0);
		}
		
		// 見える
		SetPlayerRenderHide(client, false);

		// 視点を戻す
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		
		// モデル削除
		DeleteModel(client);
		
		// 速度戻す
		TF2_SetPlayerDefaultSpeed(client);
		
		// 次に使用可能になるまでの時間設定
		g_NextUseTime[client] = GetGameTime() + GetConVarFloat(g_ChargeTime);
				
		// パワーチャージタイマー発動
		if(g_PowerChargeTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_PowerChargeTimer[client]);
			g_PowerChargeTimer[client] = INVALID_HANDLE;
		}
		g_PowerChargeTimer[client] = CreateTimer(GetConVarFloat(g_ChargeTime), Timer_PowerChargeTimer, client);
		
		
	}
	else
	{
		// もしプレイヤーが移動したら樽も移動
		if( g_DisguiseModel[client] != -1 && g_DisguiseModel[client] != 0)
		{
			if( IsValidEntity(g_DisguiseModel[client]) )
			{
				new Float:Pos[3];
				GetClientAbsOrigin(client, Pos);
				Pos[2] +=0.0;
				TeleportEntity(g_DisguiseModel[client], Pos, NULL_VECTOR, NULL_VECTOR);
			}
		}
		
		
		// 移動速度落とす
		//TF2_SetPlayerSpeed(client, 0.5);
		
	}
	
}

/////////////////////////////////////////////////////////////////////
//
// パワーチャージ完了
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_PowerChargeTimer(Handle:timer, any:client)
{
	g_PowerChargeTimer[client] = INVALID_HANDLE;
	
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		PrintToChat(client, "\x05%T", "POWER_CHARGED_SPYJUTSU", client);
		EmitSoundToClient(client, SOUND_CHARGE_POWER, client, _, _, _, 1.0);
	}
}

/////////////////////////////////////////////////////////////////////
//
// 樽破壊
//
/////////////////////////////////////////////////////////////////////
stock BreakDisguise(any:client)
{
	// 樽の破片
	new gibModel = CreateEntityByName("prop_physics_override");
	if (IsValidEdict(gibModel))
	{
		SetEntityModel(gibModel, MDL_DISGUISE);
		DispatchSpawn(gibModel);
		if(GetClientTeam(client) == 2)
		{
			SetVariantInt(1);
			AcceptEntityInput(gibModel, "Skin");
		}
		
		// モデルをプレイヤーの位置に移動
		new Float:pos[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", pos);
		pos[2] += 30.0;
		new Float:ang[3];
		GetClientEyeAngles(client, ang);
		ang[0] = 0.0;
		ang[1] += 40.0;
		ang[2] = 0.0;
		TeleportEntity(gibModel, pos, ang, NULL_VECTOR);
		AcceptEntityInput(gibModel, "Break");
		RemoveEdict(gibModel);
	}	
}
/////////////////////////////////////////////////////////////////////
//
// ロッカータッチ
//
/////////////////////////////////////////////////////////////////////
//public EntityOutput_StartTouch( const String:output[], caller, activator, Float:delay )
//{
//	PrintToChat(activator, "Touch");
//	if(TF2_EdictNameEqual(activator, "player"))
//	{
//		// 次に使用可能になるまでの時間設定
//		g_NextUseTime[activator] = GetGameTime();
//	}
//}



/////////////////////////////////////////////////////////////////////
//
// モデル削除
//
/////////////////////////////////////////////////////////////////////
stock DeleteModel(any:client)
{
	// モデルを削除
	if( g_DisguiseModel[client] != -1 && g_DisguiseModel[client] != 0)
	{
		if( IsValidEntity(g_DisguiseModel[client]) )
		{
			// 樽破壊
			BreakDisguise(client);
			
			ActivateEntity(g_DisguiseModel[client]);
			RemoveEdict(g_DisguiseModel[client]);
			g_DisguiseModel[client] = -1;
		}	
	}
	
	g_IsDisguiseActive[client] = false;
}

/////////////////////////////////////////////////////////////////////
//
// チャージ時間
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_ChargeTime(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 1.0～60.0まで
	if (StringToFloat(newValue) < 1.0 || StringToFloat(newValue) > 60.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 1.0 and 60.0");
	}
}	