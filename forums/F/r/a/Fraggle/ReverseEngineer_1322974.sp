/////////////////////////////////////////////////////////////////////
// Changelog
/////////////////////////////////////////////////////////////////////
// 2010/10/12 - 0.0.6
// fixed for ojects.txt changes
// made use of sm_rmf_reverseengineer_chargetime_mag
// 2010/03/01 - 0.0.5
// ・1.3.1でコンパイル
// 2009/10/06 - 0.0.4
// ・内部処理を変更
// 2009/08/29 - 0.0.3
// ・単体動作に対応。
// ・1.2.3でコンパイル
// 2009/08/14 - 0.0.1
// ・クラスレスアップデートに対応(1.2.2でコンパイル)

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
#define PL_NAME "RMF Reverse Engineer"
#define PL_DESC "Reverse Engineer"
#define PL_VERSION "0.0.6"
#define PL_TRANSLATION "reverseengineer.phrases"

#define SOUND_TELEPORTER_SEND "weapons/teleporter_send.wav"
#define SOUND_TELEPORTER_RECEIVE "weapons/teleporter_receive.wav"

#define EFFECT_TELEPORT_FLASH "teleported_flash"
#define EFFECT_TELEPORT_RED "teleported_red"
#define EFFECT_TELEPORT_BLU "teleported_blue"

#define EFFECT_PLAYER_GLOW_RED "player_glowred"
#define EFFECT_PLAYER_GLOW_BLU "player_glowblue"

#define EFFECT_TELEPORTIN_RED "teleportedin_red"
#define EFFECT_PLAYER_RECENT_RED "player_recent_teleport_red"
#define EFFECT_PLAYER_DRIPS_RED "player_dripsred"
#define EFFECT_PLAYER_SPARKLES_RED "player_sparkles_red"

#define EFFECT_TELEPORTIN_BLU "teleportedin_blue"
#define EFFECT_PLAYER_RECENT_BLU "player_recent_teleport_blue"
#define EFFECT_PLAYER_DRIPS_BLU "player_drips_blue"
#define EFFECT_PLAYER_SPARKLES_BLU "player_sparkles_blue"




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
new Handle:g_ChargeTimeMag = INVALID_HANDLE;				// ConVarチャージ時間

new Handle:g_SetChargeTimer[MAXPLAYERS+1]	= INVALID_HANDLE;	// チャージ時間変更タイマー
new Handle:g_FlashEffectTimer[MAXPLAYERS+1]	= INVALID_HANDLE;	// フラッシュエフェクトタイマー
new Handle:g_PlayerEffectTimer[MAXPLAYERS+1]	= INVALID_HANDLE;	// 粒子エフェクトタイマー

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
		CreateConVar("sm_rmf_tf_reverseengineer", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_reverseengineer","1","Reverse Engineer Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVarフック
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);

		g_ChargeTimeMag = CreateConVar("sm_rmf_reverseengineer_chargetime_mag","2.0","Charge time magnification (0.0-10.0)");
		HookConVarChange(g_ChargeTimeMag, ConVarChange_Magnification);

		// アビリティクラス設定
		CreateConVar("sm_rmf_reverseengineer_class", "9", "Ability class");
	}

	// マップスタート
	if(StrEqual(name, EVENT_MAP_START))
	{
		PrecacheSound(SOUND_TELEPORTER_SEND, true);
		PrecacheSound(SOUND_TELEPORTER_RECEIVE, true);
		PrePlayParticle(EFFECT_TELEPORT_FLASH);

		PrePlayParticle(EFFECT_TELEPORT_RED);
		PrePlayParticle(EFFECT_TELEPORTIN_RED);
		PrePlayParticle(EFFECT_PLAYER_RECENT_RED);
		PrePlayParticle(EFFECT_PLAYER_GLOW_RED);
		PrePlayParticle(EFFECT_PLAYER_DRIPS_RED);
		PrePlayParticle(EFFECT_PLAYER_SPARKLES_RED);

		PrePlayParticle(EFFECT_TELEPORT_BLU);
		PrePlayParticle(EFFECT_TELEPORTIN_BLU);
		PrePlayParticle(EFFECT_PLAYER_RECENT_BLU);
		PrePlayParticle(EFFECT_PLAYER_GLOW_BLU);
		PrePlayParticle(EFFECT_PLAYER_DRIPS_BLU);
		PrePlayParticle(EFFECT_PLAYER_SPARKLES_BLU);
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
		// タイマークリア
		ClearTimer(g_SetChargeTimer[client]);
		ClearTimer(g_PlayerEffectTimer[client]);

		// 一応エフェクト消す
		TF2_RemoveCond( client, TF2_COND_GLOWING );

		// 説明文
		if( TF2_GetPlayerClass( client ) == TFClass_Engineer)
		{
			new String:abilityname[256];
			new String:attribute0[256];
			new String:attribute1[256];
			new String:attribute2[256];
			new String:percentage[16];

			// アビリティ名
			Format( abilityname, sizeof( abilityname ), "%T", "ABILITYNAME_REVERSEENGINEER", client );
			// アトリビュート
			Format( attribute0, sizeof( attribute0 ), "%T", "DESCRIPTION_REVERSEENGINEER_ATTRIBUTE_0", client );
			Format( attribute1, sizeof( attribute1 ), "%T", "DESCRIPTION_REVERSEENGINEER_ATTRIBUTE_1", client );
			GetPercentageString( GetConVarFloat( g_ChargeTimeMag ), percentage, sizeof( percentage ) )
			Format( attribute2, sizeof( attribute2 ), "%T", "DESCRIPTION_REVERSEENGINEER_ATTRIBUTE_2", client, percentage );

			// 1ページ目
			Format( g_PlayerHintText[ client ][ 0 ], HintTextMaxSize , "\"%s\"\n%s", abilityname, attribute0 );
			// 2ページ目
			Format( g_PlayerHintText[ client ][ 1 ], HintTextMaxSize , "%s\n%s", attribute1, attribute2 );

		}
	}


	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// 発動チェック
//
/////////////////////////////////////////////////////////////////////
public FrameAction(any:client)
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// エンジニアのみ
		if(TF2_GetPlayerClass(client) == TFClass_Engineer && g_AbilityUnlock[client])
		{
			// キーチェック
			if( CheckElapsedTime(client, 2.0) )
			{
				if ( GetClientButtons(client) & IN_ATTACK2 )
				{
					// キーを押した時間を保存
					SaveKeyTime(client);

					if(!TF2_CurrentWeaponEqual(client, "CTFWeaponBuilder"))
					{
						ReverseTeleport(client);
					}

				}

			}

		}
	}
}


/////////////////////////////////////////////////////////////////////
//
// 逆テレポ
//
/////////////////////////////////////////////////////////////////////
public ReverseTeleport(client)
{
	new groundEntity = GetEntPropEnt(client, Prop_Data, "m_hGroundEntity");

	// 足元にテレポーター出口？
	if( groundEntity > 0 )
	{

		new String:className[64];
		GetEdictClassname(groundEntity, className, sizeof(className));

		new TFObjectMode:classMode = TF2_GetObjectMode(groundEntity);

		if(StrEqual(className, "obj_teleporter") && classMode == TFObjectMode:1)
		{

			// 稼働中のみ
			if(GetEntProp(groundEntity, Prop_Send, "m_iState") == 2)
			{

				// 入り口を探す
				new entrance = -1;

				while ((entrance = FindEntityByClassname(entrance, "obj_teleporter")) != -1)
				{

					classMode = TF2_GetObjectMode(entrance);
					if(classMode == TFObjectMode:0)
					{

						// 持ち主チェック
						new iOwner = GetEntPropEnt(entrance, Prop_Send, "m_hBuilder");
						if(iOwner == client)
						{
							// 稼働中のみ
							if(GetEntProp(entrance, Prop_Send, "m_iState") == 2)
							{
								//GetEntProp(entrance, Prop_Send, "m_iState", 1);
								// リセット
								SetEntProp(entrance, Prop_Send, "m_iState", 3);
								SetEntProp(groundEntity, Prop_Send, "m_iState", 3);

								// タイマー延長設定
								ClearTimer(g_SetChargeTimer[client]);
								g_SetChargeTimer[client] = CreateTimer(0.5, Timer_SetCharge, client);

								// フラッシュエフェクトタイマー設定
								ClearTimer(g_FlashEffectTimer[client]);
								g_FlashEffectTimer[client] = CreateTimer(0.8, Timer_FlashEffect, client);

								// プレイヤーエフェクトタイマー設定
								TF2_RemoveCond( client, TF2_COND_GLOWING );
								TF2_AddCond( client, TF2_COND_GLOWING );
								ClearTimer(g_PlayerEffectTimer[client]);
								g_PlayerEffectTimer[client] = CreateTimer(10.0, Timer_PlayerEffect, client);

								// 入り口へテレポート
								new Float:entrancePos[3];
								GetEntPropVector(entrance, Prop_Data, "m_vecAbsOrigin", entrancePos);
								entrancePos[2] += 15.0;
								new Float:entranceAng[3];
								GetEntPropVector(entrance, Prop_Data, "m_angRotation", entranceAng);

								TeleportEntity(client, entrancePos, entranceAng, NULL_VECTOR);

								// エフェクトとサウンド
								EmitSoundToAll(SOUND_TELEPORTER_SEND, groundEntity, _, _, SND_CHANGEPITCH, 1.0, 90);
								EmitSoundToAll(SOUND_TELEPORTER_RECEIVE, entrance, _, _, SND_CHANGEPITCH, 1.0, 90);

								AttachParticle(groundEntity, EFFECT_TELEPORT_FLASH, 0.1);
								//AttachParticle(entrance, "teleportedin_red", 1.0);
								//AttachParticle(groundEntity, "teleported_red", 1.0);

								ScreenFade(client, 255, 255, 255, 128, 300, IN);

								if(TFTeam:GetClientTeam(client) == TFTeam_Red)
								{
									AttachParticle(groundEntity, EFFECT_TELEPORT_RED, 1.0);
									AttachParticle(entrance, EFFECT_TELEPORTIN_RED, 1.0);
									//AttachParticle(client, EFFECT_PLAYER_GLOW_RED, 10.0);
								}
								else
								{
									AttachParticle(groundEntity, EFFECT_TELEPORT_BLU, 1.0);
									AttachParticle(entrance, EFFECT_TELEPORTIN_BLU, 1.0);
									//AttachParticle(client, EFFECT_PLAYER_GLOW_BLU, 10.0);
								}

								// 出口に乗ってるやつ爆死
								new maxclients = GetMaxClients();
								for (new victim = 1; victim <= maxclients; victim++)
								{
									if(IsClientInGame(victim) && IsPlayerAlive(victim))
									{
										groundEntity = GetEntPropEnt(victim, Prop_Data, "m_hGroundEntity");

										// 足元にテレポーター出口？
										if( groundEntity != -1 )
										{
											GetEdictClassname(groundEntity, className, sizeof(className));

											if(StrEqual(className, "obj_teleporter"))
											{
												classMode = TF2_GetObjectMode(groundEntity);
												if(classMode == TFObjectMode:0)
												{
													FakeClientCommand(victim, "explode");
												}
											}
										}
									}
								}

								//AttachParticleBone(client, EFFECT_PLAYER_DRIPS_RED, "partyhat", 10.0);
								//PrePlayParticle(EFFECT_PLAYER_RECENT_RED);
								//PrePlayParticle(EFFECT_PLAYER_GLOWED);
								//PrePlayParticle(EFFECT_PLAYER_DRIPS_RED);

							}
						}
					}
				}
			}
		}

	}

}

/////////////////////////////////////////////////////////////////////
//
// テレポーターチャージ設定
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_SetCharge(Handle:timer, any:client)
{
	g_SetChargeTimer[client] = INVALID_HANDLE;

	// 入り口を探す
	new entrance = -1;
	while ((entrance = FindEntityByClassname(entrance, "obj_teleporter")) != -1)
	{

		new TFObjectMode:classMode = TF2_GetObjectMode(entrance);
		if(classMode == TFObjectMode:0)
		{

			// 持ち主チェック
			new iOwner = GetEntPropEnt(entrance, Prop_Send, "m_hBuilder");
			if(iOwner == client)
			{
				// 延長長時間設定
				switch(GetEntProp(entrance, Prop_Send, "m_iUpgradeLevel"))
				{
				case 1:
					SetEntPropFloat(entrance, Prop_Send, "m_flRechargeTime", GetGameTime() + (10.0 * GetConVarFloat( g_ChargeTimeMag ))-0.5);
				case 2:
					SetEntPropFloat(entrance, Prop_Send, "m_flRechargeTime", GetGameTime() + (5.0 * GetConVarFloat( g_ChargeTimeMag ))-0.5);
				case 3:
					SetEntPropFloat(entrance, Prop_Send, "m_flRechargeTime", GetGameTime() + (3.0 * GetConVarFloat( g_ChargeTimeMag ))-0.5);
				}
			}
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// エフェクト設定
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_FlashEffect(Handle:timer, any:client)
{
	g_FlashEffectTimer[client] = INVALID_HANDLE;

	// 出口を探す
	new teleporter_exit = -1;
	while ((teleporter_exit = FindEntityByClassname(teleporter_exit, "obj_teleporter")) != -1)
	{

		new TFObjectMode:classMode = TF2_GetObjectMode(teleporter_exit);
		if(classMode == TFObjectMode:0)
		{

			// 持ち主チェック
			new iOwner = GetEntPropEnt(teleporter_exit, Prop_Send, "m_hBuilder");
			if(iOwner == client)
			{
				AttachParticle(teleporter_exit, EFFECT_TELEPORT_FLASH, 0.1);
			}
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// プレイヤーエフェクト終了
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_PlayerEffect(Handle:timer, any:client)
{
	g_PlayerEffectTimer[client] = INVALID_HANDLE;

	if( IsClientInGame( client ) && IsPlayerAlive( client ) )
	{
		TF2_RemoveCond( client, TF2_COND_GLOWING );
	}

}
