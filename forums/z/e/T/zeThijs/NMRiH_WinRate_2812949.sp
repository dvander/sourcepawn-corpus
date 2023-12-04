/**
 *	進捗状況コメント
 *
 *	・ [作業中の行数] ...	x
 *	・ [作業内容] ... x
 *
 * 
 * 
 * 
 *
 *
 *
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#define PLUGIN_VERSION "1.0.7"
#define MAXPLAYERSREAL 9 	//add support for non official 9 players

public Plugin myinfo = {
	name = "[NMRiH] Win Rate",
	author = "Dayonn_dayonn",
	description = "Record and Display the complete average.",
	version = PLUGIN_VERSION
};



KeyValues hConfig;										// NMRiH_WinRate.cfg へのハンドル。ラウンドのたびに読みに行くので、接続したままにする。
char sDB_KeyValues[128];								// データベース接続の設定名（データベース名ではない）。configから読み込む。
char sTable[128];										// メインのテーブル名。configから読み込む。
Database m_hDB = null;									// データベースのハンドル。
DBStatement m_hSQL_Insert = null;						// レコード挿入のプリペアドステートメント。
DBStatement m_hSQL_Find = null;							// レコード検索のプリペアドステートメント。
DBStatement m_hSQL_Update = null;						// レコード更新のプリペアドステートメント。
DBStatement m_hSQL_this_map_Get_Ave_All = null;			// this_map にて、全プレイヤーの平均実績の文字列"Ave_ALL"を取得するプリペアドステートメント。
DBStatement m_hSQL_this_map_Get_Ave_Online = null;		// this_map にて、接続中プレイヤーの平均実績の文字列"Ave_Online"を取得するプリペアドステートメント。
DBStatement m_hSQL_this_map_Get_Plyer_Record = null;	// this_map にて、"steam_id"とプレイヤーごとの実績の文字列"Plyer_Record"を取得するプリペアドステートメント。
DBStatement m_hSQL_Get_Rank = null;						// rank_you と rank_online にて、マップ難易度ランキングの文字列"Rank"を取得するプリペアドステートメント。
DBStatement m_hSQL_Get_Rank_All = null;					// rank_all にて、マップ難易度ランキングの文字列"Rank_All"を取得するプリペアドステートメント。
DBStatement m_hSQL_Delete_agreement = null;				// あるsteamIDの全レコードを削除するプペアドステートメント。

char sMap[64] = "";							// 記録対象のmap名。
char sOnRoundStart_name[MAXPLAYERSREAL+1][32];				// ゲーム参加者の名前リスト。[最大8名だが、要素番号を1～8で指定する(0は使わない)ので9] 初期化しない。
char sOnRoundStart_steamID[MAXPLAYERSREAL+1][32];			// ゲーム参加者のsteamIDリスト。[最大8名] 初期化しない。
char sAlive_OnEnd_steamID[MAXPLAYERSREAL+1][32];			// ラウンド・あるいはマップ終了時に生き残っていたプレイヤーのsteamIDリスト。[最大8名] 初期化しない。
bool bRound_reset_Vote;						// ラウンドをリセットしてしまうような投票かどうか。初期化しない。
int iNoCount_AlivePlayers_OnEnd = 0;		// ラウンド・あるいはマップ終了時に生き残っていたプレイヤーのプレイ回数を数えないかどうか。0で未判定、1で数える(通常)、2で数えない(キャンセル処理)。要初期化。

//Load_config tries to parse server name before it has been set.
//Causes it to parse default name, incorrectly!
//FIX:
//Late load using timer
public void OnPluginStart(){
	if (Load_config())
		CreateTimer(1.0, LateLoad);
	else
	{
		Connect_database();
		Create_Prepared_Statements();
		LoadTranslations("NMRiH_WinRate.phrases");

		HookEvent("nmrih_round_begin", Event_nmrih_round_begin, EventHookMode_Post);
		HookEvent("game_restarting", Event_game_restarting, EventHookMode_Post);
		HookUserMessage(GetUserMessageId("VoteStart"), Event_vote_start, false, dummy);
		HookUserMessage(GetUserMessageId("VotePass"), Event_vote_pass, false, dummy);
		HookEvent("player_extracted", Event_player_extracted, EventHookMode_Post);
		RegConsoleCmd("changelevel_next", Event_changelevel_next);	//コンソールコマンドをフック
		RegConsoleCmd("changelevel", Event_changelevel);	//コンソールコマンドをフック


		RegConsoleCmd("winrate", Menu_main);
		RegConsoleCmd("wr", Menu_main);
	}
	
}




// ダミー、何もしない。
public void dummy(UserMsg msg_id, bool sent){
}



// 	Configファイルからデータベース関連の設定値を読み込み、設定する。記録しないマップリストと削除する経過日数はここでは扱わない。
//  Returns 1 if late load required
public int Load_config(){
	hConfig = new KeyValues("WinRate_Config");	// CloseHandle() or delete でクローズしないといけない

	char sConfig_Path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfig_Path, sizeof(sConfig_Path), "configs/NMRiH_WinRate.cfg");
														// configファイルのsourcemodフォルダからの相対パスを指定
	if (!hConfig.ImportFromFile(sConfig_Path)) {
		SetFailState("[Win Rate]: Couldn't load 'NMRiH_WinRate.cfg' from ...addons/sourcemod/configs/");
	}

	hConfig.JumpToKey("Server_List",false);

	char sServer_Name[128];
	char sConfig_Name[128];

	
	GetConVarString(FindConVar("hostname"), sServer_Name, sizeof(sServer_Name));

	if (StrEqual(sServer_Name, "No More Room in Hell", false))
		return 1;

	if (!hConfig.JumpToKey(sServer_Name,false)) {		// サーバー名を探して下の階層へ移動
		PrintToServer("[Win Rate]: This server name is '%s'.",sServer_Name);

		if(!hConfig.GotoFirstSubKey(false)) {
			PrintToServer("[Win Rate]: Nothing KeyValue.");
		}else{
			hConfig.GetSectionName(sConfig_Name, sizeof(sConfig_Name));
			PrintToServer("[Win Rate]: Section of KeyValues -- '%s'",sConfig_Name);
			while (hConfig.GotoNextKey(false)) {
				hConfig.GetSectionName(sConfig_Name, sizeof(sConfig_Name));
				PrintToServer("[Win Rate]: Section of KeyValues -- '%s'",sConfig_Name);
			}
			hConfig.GoBack();		
		}	
		SetFailState("[Win Rate]: Couldn't find this server name \"%s\" in 'NMRiH_WinRate.cfg'. Please edit it.", sServer_Name);
	}

	hConfig.GetString("Database_keyvalues",sDB_KeyValues,sizeof(sDB_KeyValues),"not found");		// 文字列を取得
	if (StrEqual(sDB_KeyValues, "not found")) {
		SetFailState("[Win Rate]: Couldn't read 'Database_keyvalues' in 'NMRiH_WinRate.cfg'. Please edit it.");
	}

	hConfig.GetString("Rate_table",sTable,sizeof(sTable),"not found");
	if (StrEqual(sTable, "not found")) {
		SetFailState("[Win Rate]: Couldn't read 'Rate_table' in 'NMRiH_WinRate.cfg'. Please edit it.");
	}

	hConfig.GoBack();
	hConfig.GoBack();		// ツリーのトップに戻す
	return 0;
}

int limit = 0;	//okay fine i'll limit recurse just in case.
public Action LateLoad(Handle timer, any data)
{
	if (Load_config() && limit<25)	//Recursive load, what could go wrong? ;)
	{
		limit++;
		CreateTimer(1.0, LateLoad);	
	}
	else
	{	
		Connect_database();
		Create_Prepared_Statements();
		LoadTranslations("NMRiH_WinRate.phrases");

		HookEvent("nmrih_round_begin", Event_nmrih_round_begin, EventHookMode_Post);
		HookEvent("game_restarting", Event_game_restarting, EventHookMode_Post);
		HookUserMessage(GetUserMessageId("VoteStart"), Event_vote_start, false, dummy);
		HookUserMessage(GetUserMessageId("VotePass"), Event_vote_pass, false, dummy);
		HookEvent("player_extracted", Event_player_extracted, EventHookMode_Post);
		RegConsoleCmd("changelevel_next", Event_changelevel_next);	//コンソールコマンドをフック
		RegConsoleCmd("changelevel", Event_changelevel);	//コンソールコマンドをフック


		RegConsoleCmd("winrate", Menu_main);
		RegConsoleCmd("wr", Menu_main);	
	}
	return Plugin_Stop;
}




public void Connect_database(){
	if (!SQL_CheckConfig(sDB_KeyValues)) {		// databases.cfg にデータベース設定が記述されていることを確認。
		SetFailState("[Win Rate]: Couldn't find KeyValues '%s' in 'databases.cfg'. Please edit it.",sDB_KeyValues);
	}

	char sDB_Error[256];
	m_hDB = SQL_Connect(sDB_KeyValues, true, sDB_Error, sizeof(sDB_Error));
	if (m_hDB == INVALID_HANDLE) {
		PrintToServer("[Win Rate]: Couldn't connect Database. Check 'database' value in 'databases.cfg', and create database for MySQL.");
		PrintToServer("[Win Rate]: To create database for MySQL, input forrow at MySQL Command Line Client.");
		PrintToServer("[Win Rate]: If 'database' name is 'nmrih_winrate' , input ' create database nmrih_winrate; '");
		SetFailState("[Win Rate]: Not connect Database.");
	}

	// 以下、テーブルがない場合はテーブル作成。
	char sQuery[256];
	/**
	 *	FormatEx(sQuery, sizeof(sQuery), "create table if not exists %s "
	 *	... "(steam_id char(32), player_name char(255), map_name char(255), clear_rate float(5, 2), clear_count int unsigned, play_count int unsigned, play_date date)",
	 *	sTable);
	 * v1.0.6 にてマップ名文字数を 255 -> 64 へ修正。プレイヤー名を255 -> 32 へ修正。
	 */
	FormatEx(sQuery, sizeof(sQuery), "create table if not exists %s "
		... "(steam_id char(32), player_name char(32), map_name char(64), clear_rate float(5, 2), clear_count int unsigned, play_count int unsigned, play_date date)",
		sTable);

	SQL_FastQuery(m_hDB, sQuery);
}



public void	Create_Prepared_Statements(){
	char sPrepared[512];
	char sDB_Error[256];

	// レコードの新規挿入。
	FormatEx(sPrepared, sizeof(sPrepared), "INSERT INTO %s VALUES(?, ?, ?, ?, ?, 1, CURDATE())", sTable);
		// 項目 0		steamID				データ例: [U:9:123456789]
		// 項目 1		プレイヤー名			データ例: player_3
		// 項目 2		map名				データ例: nmo_testmap_5
		// 項目 3		クリア確率				データ例: 100	--	これはMySQL側で小数点以下2桁が追加される。入力段階では0か100。
		// 項目 4		クリア回数				データ例: 1	--	クリアしたら1、クリアできなかったら0
	m_hSQL_Insert = SQL_PrepareQuery(m_hDB, sPrepared, sDB_Error, sizeof(sDB_Error));

	// 特定のレコードを取得。
	FormatEx(sPrepared, sizeof(sPrepared), "SELECT steam_id FROM %s WHERE steam_id = ? AND map_name = ?", sTable);
	// 対象のレコードがあるかどうかをチェックしているだけなので、steamIDだけを取得している。
		// 項目 0		steamID				データ例: [U:9:12345678]
		// 項目 1		map名				データ例: nmo_testmap_5
	m_hSQL_Find = SQL_PrepareQuery(m_hDB, sPrepared, sDB_Error, sizeof(sDB_Error));

	// 特定のレコードを更新。
	FormatEx(sPrepared, sizeof(sPrepared), "UPDATE %s SET player_name = ?, clear_rate = (clear_count + ?)  /  (play_count + 1) * 100, "
		... "clear_count = clear_count + ?,  play_count = play_count + 1,  play_date = CURDATE() WHERE steam_id = ? AND map_name = ?", sTable);
		// 項目 0		プレイヤー名			データ例: player_x		--	名前が変わるかもしれないから、毎回更新。
		// 項目 1		クリアした?				データ例: 0	--	クリアしたら1,出来なかったら0
		// 項目 2		クリアした?				データ例: 0	--	クリアしたら1,出来なかったら0	
		// 項目 3		steamID				データ例: [U:9:123456789]
		// 項目 4		map名				データ例: nmo_testmap_5
	m_hSQL_Update = SQL_PrepareQuery(m_hDB, sPrepared, sDB_Error, sizeof(sDB_Error));

	// this_map にて、全プレイヤーの平均実績の文字列"Ave_ALL"を取得。
	FormatEx(sPrepared, sizeof(sPrepared), "SELECT CONCAT('(All players)', '         --  ', FORMAT(AVG(clear_rate), 2), ' %%  --  ', "
		... "FORMAT(SUM(clear_count), 0), ' / ', FORMAT(SUM(play_count), 0)) AS Ave_ALL FROM %s WHERE map_name = ?", sTable);
		// 項目 0		map名				データ例: nmo_testmap_5
	m_hSQL_this_map_Get_Ave_All = SQL_PrepareQuery(m_hDB, sPrepared, sDB_Error, sizeof(sDB_Error));

	// this_map にて、接続中プレイヤーの平均実績の文字列"Ave_Online"を取得。
	FormatEx(sPrepared, sizeof(sPrepared), "SELECT CONCAT('(Online players)', '  --  ', FORMAT(AVG(clear_rate), 2), ' %%  --  ', "
		... "FORMAT(SUM(clear_count), 0), ' / ', FORMAT(SUM(play_count), 0)) AS Ave_Online FROM %s WHERE map_name = ? AND "
		... "(steam_id = ? OR steam_id = ? OR steam_id = ? OR steam_id = ? OR steam_id = ? OR steam_id = ? "
		... "OR steam_id = ? OR steam_id = ?)", sTable);
		// 項目 0		map名				データ例: nmo_testmap_5
		// 項目 1		steamID その1			データ例: [U:1:123456789]
		// 項目 2		steamID その2			データ例: [U:2:123456789]
		// 項目 3		steamID その3			データ例: [U:3:123456789]
		// 項目 4		steamID その4			データ例: [U:4:123456789]
		// 項目 5		steamID その5			データ例: [U:5:123456789]
		// 項目 6		steamID その6			データ例: [U:6:123456789]
		// 項目 7		steamID その7			データ例: [U:7:123456789]
		// 項目 8		steamID その8			データ例: [U:8:123456789]
	m_hSQL_this_map_Get_Ave_Online = SQL_PrepareQuery(m_hDB, sPrepared, sDB_Error, sizeof(sDB_Error));

	// this_map にて、"steam_id"とプレイヤーごとの実績の文字列"Plyer_Record"を取得。
	FormatEx(sPrepared, sizeof(sPrepared), "SELECT steam_id, CONCAT(player_name, '  --  ', FORMAT(clear_rate, 2), ' %%  --  ', "
		... "FORMAT(clear_count, 0), ' / ', FORMAT(play_count, 0)) AS Plyer_Record FROM %s WHERE map_name = ? AND "
		... "(steam_id = ? OR steam_id = ? OR steam_id = ? OR steam_id = ? OR steam_id = ? OR steam_id = ? OR steam_id = ? OR "
		... "steam_id = ?) ORDER BY clear_rate ASC", sTable);
		// 項目 0		map名				データ例: nmo_testmap_5
		// 項目 1		steamID その1			データ例: [U:1:123456789]
		// 項目 2		steamID その2			データ例: [U:2:123456789]
		// 項目 3		steamID その3			データ例: [U:3:123456789]
		// 項目 4		steamID その4			データ例: [U:4:123456789]
		// 項目 5		steamID その5			データ例: [U:5:123456789]
		// 項目 6		steamID その6			データ例: [U:6:123456789]
		// 項目 7		steamID その7			データ例: [U:7:123456789]
		// 項目 8		steamID その8			データ例: [U:8:123456789]
	m_hSQL_this_map_Get_Plyer_Record = SQL_PrepareQuery(m_hDB, sPrepared, sDB_Error, sizeof(sDB_Error));

	// オンラインプレイヤーのマップ難易度ランキングの文字列"Rank"を取得。1～８人対応。
	FormatEx(sPrepared, sizeof(sPrepared), "SELECT map_name, CONCAT(map_name, '  --  ', FORMAT(SUM(clear_rate) / ?, 2), "
		... "' %%  --  ', FORMAT(SUM(clear_count), 0), ' / ', FORMAT(SUM(play_count), 0)) FROM %s WHERE steam_id = ? OR steam_id = ? OR steam_id = ? "
		... "OR steam_id = ? OR steam_id = ? OR steam_id = ? OR steam_id = ? OR steam_id = ? GROUP BY map_name ORDER BY SUM(clear_rate) ASC", sTable);
		//  ※ ソートはSUM(clear_rate)でしている。本来はSUM(clear_rate) / ? だが、定数で割っての並び替えの順番は定数で割らないで並び替える順番と同じなので、割り算を省略している。
		// 項目 0		クリア率合計を割る数		データ例: 1か4。グループのクリア率を求めるなら4を代入し、個人成績を求めるなら1を代入する。
		// 項目 1		steamID 1人目		データ例: [U:8:123456789]
		// 項目 2		steamID 2人目		データ例: [U:9:123456789]
		// 項目 3		steamID 3人目		データ例: x	-- 2人がオンラインなら、3人目以降の文字列をxにする。
		// 項目 4		steamID 4人目		データ例: x
		// 項目 5		steamID 5人目		データ例: x
		// 項目 6		steamID 6人目		データ例: x
		// 項目 7		steamID 7人目		データ例: x
		// 項目 8		steamID 8人目		データ例: x
	m_hSQL_Get_Rank = SQL_PrepareQuery(m_hDB, sPrepared, sDB_Error, sizeof(sDB_Error));

	// 全プレイヤーのマップ難易度ランキングの文字列"Rank_All"を取得。
	FormatEx(sPrepared, sizeof(sPrepared), "SELECT map_name, CONCAT(map_name, '  --  ', FORMAT(AVG(clear_rate), 2), "
		... "' %%   --   ', FORMAT(SUM(clear_count), 0), ' / ', FORMAT(SUM(play_count), 0)) FROM %s GROUP BY map_name ORDER BY AVG(clear_rate) ASC", sTable);
	m_hSQL_Get_Rank_All = SQL_PrepareQuery(m_hDB, sPrepared, sDB_Error, sizeof(sDB_Error));


	// あるsteamIDの全レコードを削除。
	FormatEx(sPrepared, sizeof(sPrepared), "DELETE FROM %s WHERE steam_id = ?", sTable);
		// 項目 0		steamID				データ例: [U:8:123456789]
	m_hSQL_Delete_agreement = SQL_PrepareQuery(m_hDB, sPrepared, sDB_Error, sizeof(sDB_Error));
}



// マップが表示された後に、動けるようになった直後。
public void Event_nmrih_round_begin(Event h_event, const char[] Event_name, bool dontBroadcast){
	CreateTimer(15.0, Fifteen_sec_after_round_begin);
}



// ラウンド開始15秒後、初期ゲーム参加者を取得。
// マップロードが遅い人や、次マップに移ってからの挨拶落ちの人（=自分）のため、遅らせている。但し nmo_hex_v2_y9v1 では 2018/03/22現在、最速クリアタイムが20秒なので、これ以上遅らせるとまずい。
public Action Fifteen_sec_after_round_begin(Handle timer){
	GetCurrentMap(sMap, sizeof(sMap));		// Configファイルの "No_Record_Maps_List" を調べ、ヒットしたら処理を飛ばす
	hConfig.JumpToKey("No_Record_Maps_List",false);
	if (hConfig.JumpToKey(sMap,false)) {
		FormatEx(sMap, sizeof(sMap), "");		//map名を削除することにより、次回のマップ記録処理をスキップ。
		hConfig.GoBack();

	}else{
		bool Any_Alive = false;

		for (int client = 1; client <= MaxClients; client++) {		// 生存者の名前・steamIDを取得
			if (IsClientInGame(client) && IsPlayerAlive(client) && !IsClientTimingOut(client)) {
				FormatEx(sOnRoundStart_name[client], sizeof(sOnRoundStart_name[]), "%N", client);
				GetClientAuthId(client, AuthId_Steam3, sOnRoundStart_steamID[client], sizeof(sOnRoundStart_steamID[]));
				Any_Alive = true;

			}else{
				FormatEx(sOnRoundStart_name[client], sizeof(sOnRoundStart_name[]), "");
				FormatEx(sOnRoundStart_steamID[client], sizeof(sOnRoundStart_steamID[]), "");		// 前回データを完全に上書きするために、elseなら""にする。
			}
		}
		if(!Any_Alive){
			FormatEx(sMap, sizeof(sMap), "");		// 全員消えた...map名を削除し、次回のマップ記録処理にてスキップするようにする。
		}
	}
	hConfig.GoBack();	// ツリーのトップに戻す
	return Plugin_Continue;
}



// 投票が開始したとき。内容を取得。
public Action Event_vote_start(UserMsg msg_id, Handle h_msg, const int[] players, int playersNum, bool reliable, bool init){
	char vote_issue[32];

	BfReadByte(h_msg);										// team
	BfReadByte(h_msg);										// 投票した人のid
	BfReadString(h_msg, vote_issue, sizeof(vote_issue));	// 投票の議題

	if (StrEqual(vote_issue, "#NMRiH_Vote_RestartRound")) {		//"#NMRiH_Vote_ChangeLevel"はフックしない。
		bRound_reset_Vote = true;
	}else{
		bRound_reset_Vote = false;
	}	
	return Plugin_Continue;
}



// 投票が可決したとき。生存者を取得 and 生存者を未プレイ扱いにするフラグを立てる。
public Action Event_vote_pass(UserMsg msg_id, Handle h_msg, const int[] players, int playersNum, bool reliable, bool init){
	if (bRound_reset_Vote) {
		Get_AlivePlayer_steamID();
		//PrintToServer("[WinRate test] リスタート投票が可決されました。生存者はプレイ回数にカウントされません。");
		iNoCount_AlivePlayers_OnEnd = 2;
	}
	return Plugin_Continue;
}



// コンソールに "changelevel_next" を入力したとき。
public Action Event_changelevel_next(int client, int iCnt_Arg){
	//PrintToServer("[WinRate test] changelevel_next 入力によるマップ変更です。生存者はプレイ回数にカウントされません。");
	iNoCount_AlivePlayers_OnEnd = 2;

	return Plugin_Continue;
}



// マップ変更が発生する直前、OnMapEndよりも前で、まだクライアントが接続している。
// コンソールへのchangelevel 入力、changelevel_next 入力、call voteによるマップ変更、mapchooserによる変更、rtvによる変更、自動的な変更、これらすべてのマップ変更をフックする。
public Action Event_changelevel(int client, int iCnt_Arg){
	if (iCnt_Arg != 0){
		Get_AlivePlayer_steamID();

		char sArg[64];
		GetCmdArg(1, sArg, sizeof(sArg));
		if (!IsMapValid(sArg)){
			//PrintToServer("[WinRate test] changelevel にてMap名の誤入力によるリスタートです。生存者はプレイ回数にカウントされません。'%s'", sArg);
			iNoCount_AlivePlayers_OnEnd = 2;
			Set_PlayerLose();
		}
	}else{
		//PrintToServer("[WinRate test] 入力した changelevel の引数がありません。");
	}
	return Plugin_Continue;
}



// マップ終了直前。生存しているプレイヤーを取得する。
public void OnMapEnd(){
//	Get_AlivePlayer_steamID();
}



// マップ開始直前。このとき、まだだれも接続していない。
public void OnMapStart(){

	// 生存者の扱いがまだ決まっていないなら、ここで判定する。
	if(iNoCount_AlivePlayers_OnEnd == 0){
		if (GetMapHistorySize() != 0){	// 0ならば、サーバ立ち上げて最初のマップなので履歴がないので、パス。

			char sMapHistory[64];	// 直前のマップ名
			char sReason[20];		// 変更理由
			int iStartTime;			// 開始時間
			GetMapHistory(0, sMapHistory, sizeof(sMapHistory), sReason, sizeof(sReason), iStartTime);
			//PrintToServer("[WinRate test] OnMapStart 前回マップ.. '%s' , 変更理由.. '%s'", sMapHistory, sReason);

			if (StrEqual(sReason,"Normal level change")){
				//PrintToServer("[WinRate test] 自動のマップ変更 or mapchooser によるマップ終了後の変更です。生存者を失敗扱いとします。");
				iNoCount_AlivePlayers_OnEnd = 1;

			}else if(StrEqual(sReason,"changelevel Command")){
				//PrintToServer("[WinRate test] call vote によるマップ変更 or changelevel 入力によるマップ変更です。生存者はプレイ回数にカウントされません。");
				iNoCount_AlivePlayers_OnEnd = 2;

			}else if(StrEqual(sReason,"Map Vote")){
				//PrintToServer("[WinRate test] mapchooser による即時マップ変更です。生存者はプレイ回数にカウントされません。");
				iNoCount_AlivePlayers_OnEnd = 2;
				/**
				 *	ConVar g_Cvar_rtv_WhenChange;	//rockthevote.sp の ConVar
				 *	g_Cvar_rtv_WhenChange = FindConVar("sm_rtv_changetime");
				 *	switch(g_Cvar_rtv_WhenChange.IntValue){
				 *		case 0:{
				 *			//	下記 1 と 2 により、case文で分岐する必要はない。
				 *			PrintToServer("[WinRate test] mapchooser による即時マップ変更です。生存者はプレイ回数にカウントされません。");
				 *			iNoCount_AlivePlayers_OnEnd = 2;
				 *		}
				 *		case 1:{
				 *			//	mapchooser で HookEvent("round_end") をしているが、NMRiHではフックされないので、1にしても実際は動作しない。
				 *			PrintToServer("[WinRate test] mapchooser によるラウンド終了後のマップ変更です。生存者を失敗扱いとします。");
				 *			iNoCount_AlivePlayers_OnEnd = 1;
				 *		}
				 *		case 2:{
				 *			//	処理フローから考えて、ここの処理に来ることはない。
				 *			PrintToServer("[WinRate test] mapchooser によるマップ終了後のマップ変更。ただし、ここには処理が来ないはず。 --error--");
				 *		}
				 *	}
				 */

			}else if(StrEqual(sReason,"RTV after mapvote")){
				//PrintToServer("[WinRate test] mp_timelimit経過後のmap投票を行い、その後のrtvにより、投票を行わないマップ変更です。生存者はプレイ回数にカウントされません。");
				iNoCount_AlivePlayers_OnEnd = 2;

			}else{
				//PrintToServer("[WinRate test] 想定外。生存者の扱いが指定されていません。 --error--");

			}
		}
	}
	Set_PlayerLose();
}



// リスタートの瞬間。
public void Event_game_restarting(Event h_event, const char[] Event_name, bool dontBroadcast){
	if(iNoCount_AlivePlayers_OnEnd == 0){
		//PrintToServer("[WinRate test] ふつうのリスタートです。生存者を失敗扱いとします。");
		iNoCount_AlivePlayers_OnEnd = 1;
	}
	Set_PlayerLose();
}



// 生存しているプレイヤーのsteamIDを取得する。
public void Get_AlivePlayer_steamID(){
	if (StrEqual(sMap, "")) return;		// ラウンド開始後15秒より前(=マップ名を取得していない)であれば、そもそも参加者を取得していないので処理する必要がない。
	//PrintToServer("[WinRate test] 生存者チェック中...") ;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i) && !IsClientTimingOut(i)) {
			GetClientAuthId(i, AuthId_Steam3, sAlive_OnEnd_steamID[i], sizeof(sAlive_OnEnd_steamID[]));
			//PrintToServer("[WinRate test] 終了直前に生存しています。'%s'",sAlive_OnEnd_steamID[i]) ;
		}else{
			FormatEx(sAlive_OnEnd_steamID[i], sizeof(sAlive_OnEnd_steamID[]), "");
		}
	}
}



// クリア失敗を記録する。
public void Set_PlayerLose(){
	if (StrEqual(sMap, "")) return;

	if (iNoCount_AlivePlayers_OnEnd == 2){	// ラウンド・あるいはマップ終了時に生き残っていたプレイヤーを未プレイ扱いにする場合、ここで間引く。
		for (int i = 1; i <= MaxClients; i++) {
			if (StrEqual(sAlive_OnEnd_steamID[i], "")) continue;
			for (int j = 1; j <= MaxClients; j++) {
				if (StrEqual(sAlive_OnEnd_steamID[i], sOnRoundStart_steamID[j])) {
					//PrintToServer("[WinRate test] カウント対象から除外しました。'%s'",sOnRoundStart_name[j]) ;
					FormatEx(sOnRoundStart_steamID[j], sizeof(sOnRoundStart_steamID[]), "");
					FormatEx(sOnRoundStart_name[j], sizeof(sOnRoundStart_name[]), "");
					break;
				}
			}
		}
	}
	for (int i = 1; i <= MaxClients; i++) {
		if (StrEqual(sOnRoundStart_steamID[i], "")) continue;
		Set_record(i, 0);
	}
	FormatEx(sMap, sizeof(sMap), "");	//初期化
	iNoCount_AlivePlayers_OnEnd = 0; 	//初期化
}



// だれかが脱出した。すぐにクリア成功の記録をする。				//多数同時にクリアする場合、nms等では全員分のフラグが出るのか? 要検証。
public void Event_player_extracted(Event h_event, const char[] Event_name, bool dontBroadcast){
	int client = GetEventInt(h_event, "player_id");
	char sClient_steamID[32];
	GetClientAuthId(client, AuthId_Steam3, sClient_steamID, sizeof(sClient_steamID));
	for (int i = 1; i <= MaxClients; i++) {
		if (StrEqual(sClient_steamID, sOnRoundStart_steamID[i])) {
			Set_record(i, 1);
			return;
		}
	}
}



// 記録処理。iはラウンド開始時プレイヤーリストの要素番号。IsWinはクリアしたかどうか。IsWinはそのまま計算に使用するので、bool型ではない。
public void Set_record(int i,int IsWin){
	SQL_LockDatabase(m_hDB);

	m_hSQL_Find.BindString(0, sOnRoundStart_steamID[i], false);
	m_hSQL_Find.BindString(1, sMap, false);
	SQL_Execute(m_hSQL_Find);
	if (SQL_FetchRow(m_hSQL_Find)) {		// レコードが見つかった場合... 上書き処理をする。
		m_hSQL_Update.BindString(0, sOnRoundStart_name[i], false);
		m_hSQL_Update.BindInt(1, IsWin, false);
		m_hSQL_Update.BindInt(2, IsWin, false);
		m_hSQL_Update.BindString(3, sOnRoundStart_steamID[i], false);
		m_hSQL_Update.BindString(4, sMap, false);
		SQL_Execute(m_hSQL_Update);
	}else{									// レコードが見つからなかった場合... 新規作成をする。
		m_hSQL_Insert.BindString(0, sOnRoundStart_steamID[i], false);
		m_hSQL_Insert.BindString(1, sOnRoundStart_name[i], false);
		m_hSQL_Insert.BindString(2, sMap, false);
		m_hSQL_Insert.BindInt(3, IsWin * 100, false);		// クリア確率。最初の書き込みなので、クリアしたら100％、失敗なら0%。なので100をかけている。
		m_hSQL_Insert.BindInt(4, IsWin, false);
		SQL_Execute(m_hSQL_Insert);
	}
	SQL_UnlockDatabase(m_hDB);

	if(IsWin == 1){		// 脱出したなら、その後のクリア失敗記録の為に、参加者リストから削除する。
		FormatEx(sOnRoundStart_name[i], sizeof(sOnRoundStart_name[]), "");
		FormatEx(sOnRoundStart_steamID[i], sizeof(sOnRoundStart_steamID[]), "");
	}
}



public Action Menu_main(int client, int args){
	Menu hMenu = new Menu(Callback_Menu_main, MENU_ACTIONS_ALL);
	char display[128];

	FormatEx(display, sizeof(display), "[ Win Rate ]\n   Ver. %s  Made by Dayonn_dayonn\n ", PLUGIN_VERSION);
	hMenu.SetTitle(display);

	FormatEx(display, sizeof(display), "%T", "this_map", client);
	hMenu.AddItem("this_map", display, ITEMDRAW_DEFAULT);

	FormatEx(display, sizeof(display), "%T", "rank_you", client);
	hMenu.AddItem("rank_you", display, ITEMDRAW_DEFAULT);
	
	FormatEx(display, sizeof(display), "%T", "rank_online", client);
	hMenu.AddItem("rank_online", display, ITEMDRAW_DEFAULT);
	
	FormatEx(display, sizeof(display), "%T", "rank_all", client);
	hMenu.AddItem("rank_all", display, ITEMDRAW_DEFAULT);

	char sDeletable[16];
	hConfig.JumpToKey("record_delete",false);
	hConfig.GetString("user_deletable",sDeletable,sizeof(sDeletable),"false");
	hConfig.GoBack();
	if (StrEqual(sDeletable, "true")) {
		hMenu.AddItem("space", "",ITEMDRAW_SPACER);		// 行スペースの挿入。番号も1つ飛ばす。
		FormatEx(display, sizeof(display), "%T", "delete", client);
		hMenu.AddItem("delete", display, ITEMDRAW_DEFAULT);
	}
		
	hMenu.AddItem("space", "",ITEMDRAW_SPACER);		// 行スペースの挿入。「0:終了」まで狭いように感じたので入れてる。番号はどうでもいいが、内部的には1つ飛んでいる。
	hMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;		//Plugin_Continueだとコンソールにエラーログが出る。
}



public int Callback_Menu_main(Menu hMenu, MenuAction action, int param1, int param2){
	switch (action) {
		case MenuAction_DrawItem: {									// メニュー内の各項目ごとにそれぞれフック。ここで書式を切り替える。
			char info[32];											// このcase 文がないと、最初のAddItemでスタイル指定をしても適用されない。
			int style;												// param1：クライアントインデックス, param2：GetMenuItemで使用するアイテム番号（いわゆる、並び順）
			hMenu.GetItem(param2, info, sizeof(info), style);		// 戻り値：新しいITEMDRAWプロパティまたは書式。0はITEMDRAW_DEFAULTなので、0を返すと、そのアイテムの書式がクリアされる。
			return style;											// 書式を変更しない場合でも、現在のアイテムの書式を返さないと、エラーが発生する。
		}
		case MenuAction_Select: {		// 8,9,0 以外を選択したときにフック。
			char info[32];				// param1：クライアントインデックス, param2：GetMenuItemで使用するアイテム番号（いわゆる、並び順）
			hMenu.GetItem(param2, info, sizeof(info));		// アイテム番号から情報文字列を取得
			
			if (StrEqual(info,"this_map"))			Menu_this_map(param1);
			else if (StrEqual(info,"rank_you"))		Menu_rank(param1,true);
			else if (StrEqual(info,"rank_online"))	Menu_rank(param1,false);
			else if (StrEqual(info,"rank_all"))		Menu_rank_all(param1);
			else if (StrEqual(info,"delete"))		Menu_delete(param1);
		}
		case MenuAction_End: {		//メニュー選択をしたり終了を選んだりして閉じられた時にフック。通常はmenuハンドルの削除に使う。
			delete hMenu;			// param1：MenuEndの理由, param2：param1がMenuEnd_Cancelledの場合、MenuCancelの理由
		}
	}
 	return 0;		// MenuAction_DrawItem か MenuAction_DisplayItem を処理する場合、スイッチブロックの後に0を返さないと、コンパイル時にエラーが出る。
					// 他のは戻り値がないが、この2つだけは戻り値が必要なため、戻り値をセットする必要がある。
}



public void Menu_this_map(int client){
	Menu hMenu = new Menu(Callback_Menu_this_map, MENU_ACTIONS_ALL);
	char sThis_map[64];				// 現在プレイ中のマップ名。sMapと同じだが、練習時間にも対応するために、別で用意。
	char display[512];				// 表示する文字列
	char sOnline_steamID[9][32];
	char sOnline_name[9][32];
	char sReturn_steamID[32];	// MySQLからの返り値のsteamIDを格納。

	GetCurrentMap(sThis_map, sizeof(sThis_map));
	FormatEx(display, sizeof(display), "%T", "this_map_Title",client);
	hMenu.SetTitle(display);

	// 観戦者も含め、接続中プレイヤーの名前・steamIDを取得。
	for (int i = 1; i <= 8; i++) {
		if (i <= MaxClients) {
			if (IsClientInGame(i) && !IsClientTimingOut(i)) {
				GetClientAuthId(i, AuthId_Steam3, sOnline_steamID[i], sizeof(sOnline_steamID[]));
				FormatEx(sOnline_name[i], sizeof(sOnline_name[]), "%N", i);
			}else{
				FormatEx(sOnline_steamID[i], sizeof(sOnline_steamID[]), "x");		// 8名全員のIDをMySQLに渡すので、検索にヒットしないよう、x（バツというつもり）を代入しておく。
				FormatEx(sOnline_name[i], sizeof(sOnline_name[]), "x");
			}
		}else{
			FormatEx(sOnline_steamID[i], sizeof(sOnline_steamID[]), "x");		// MaxClientsが2名の場合もある。
			FormatEx(sOnline_name[i], sizeof(sOnline_name[]), "x");
		}
	}

	// 全プレイヤーの平均実績"Ave_ALL"を取得。
	SQL_BindParamString(m_hSQL_this_map_Get_Ave_All, 0, sThis_map, false);
	SQL_Execute(m_hSQL_this_map_Get_Ave_All);
	if (SQL_FetchRow(m_hSQL_this_map_Get_Ave_All)) {
		if (SQL_IsFieldNull(m_hSQL_this_map_Get_Ave_All,0)){
 			FormatEx(display, sizeof(display), "(All Players)         --  0.00 %  --  0 / 0");		// NULLだったら、別の文字列を挿入			
		}else{
			SQL_FetchString(m_hSQL_this_map_Get_Ave_All, 0, display, sizeof(display));
		}
	}
	hMenu.AddItem("Ave_ALL", display, ITEMDRAW_DISABLED);

	// 接続中プレイヤーの平均実績"Ave_Online"を取得。
	SQL_BindParamString(m_hSQL_this_map_Get_Ave_Online, 0, sThis_map, false);
	for (int i = 1; i <= 8; i++) SQL_BindParamString(m_hSQL_this_map_Get_Ave_Online, i, sOnline_steamID[i], false);
	SQL_Execute(m_hSQL_this_map_Get_Ave_Online);
	if (SQL_FetchRow(m_hSQL_this_map_Get_Ave_Online)) {
		if (SQL_IsFieldNull(m_hSQL_this_map_Get_Ave_Online,0)){
 			FormatEx(display, sizeof(display), "(Online Players)  --  0.00 %  --  0 / 0");		// NULLだったら、別の文字列を挿入			
		}else{
			SQL_FetchString(m_hSQL_this_map_Get_Ave_Online, 0, display, sizeof(display));
		}
	}
	FormatEx(display, sizeof(display), "%s\n ",display);		// 改行を追加			
	hMenu.AddItem("Ave_Online", display, ITEMDRAW_DISABLED);

	// 接続中のプレイヤーごとの実績"Plyer_Record"を取得。
	SQL_BindParamString(m_hSQL_this_map_Get_Plyer_Record, 0, sThis_map, false);
	for (int i = 1; i <= 8; i++) SQL_BindParamString(m_hSQL_this_map_Get_Plyer_Record, i, sOnline_steamID[i], false);
	SQL_Execute(m_hSQL_this_map_Get_Plyer_Record);
	while (SQL_FetchRow(m_hSQL_this_map_Get_Plyer_Record)) {
		SQL_FetchString(m_hSQL_this_map_Get_Plyer_Record, 0, sReturn_steamID, sizeof(sReturn_steamID));
		SQL_FetchString(m_hSQL_this_map_Get_Plyer_Record, 1, display, sizeof(display));
		hMenu.AddItem(sReturn_steamID, display, ITEMDRAW_DISABLED);

		for (int i = 1; i <= 8; i++) {
			if (StrEqual(sReturn_steamID, sOnline_steamID[i])){
				FormatEx(sOnline_steamID[i], sizeof(sOnline_steamID[]), "x"); //記録が見つかったらリストから消す。
				FormatEx(sOnline_name[i], sizeof(sOnline_name[]), "x");
			}
		}
	}	
	for (int i = 1; i <= 8; i++) {
		if (!StrEqual(sOnline_steamID[i],"x" )){

			FormatEx(display, sizeof(display), "%s  --  0.00 %  --  0 / 0", sOnline_name[i]);
			hMenu.AddItem(sOnline_steamID[i], display, ITEMDRAW_DISABLED);
		}
	}
	hMenu.ExitBackButton = true;
	hMenu.Display(client, MENU_TIME_FOREVER);
}



public int Callback_Menu_this_map(Menu hMenu, MenuAction action, int param1, int param2){
	switch(action)
	{
		case MenuAction_DrawItem: {		// メニュー内の各項目ごとにそれぞれフック。ここで書式を切り替える。このcase 文がないと、最初のAddItemでスタイル指定をしても適用されない。
			int style;					// 書式を変更しない場合でも、現在のアイテムの書式を返さないと、エラーが発生する。
			char info[32];
			hMenu.GetItem(param2, info, sizeof(info), style);
			return style;
		}
		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack) Menu_main(param1, 0);
		}
		case MenuAction_End:delete hMenu;
	}
	return 0;
}



public void Menu_rank(int client,bool IsOnly_You){
	Menu hMenu = new Menu(Callback_Menu_rank, MENU_ACTIONS_ALL);
	char sThis_map[64];				// 現在プレイ中のマップ名。sMapと同じだが、練習時間にも対応するために、別で用意。
	char display[512];				// 表示する文字列
	char sOnline_steamID[9][32];
	char sReturn_map[64];			// MySQLからの返り値のmap名
	char sTemp[512];				// MySQLからの返り値の表示用文字列
	int iFirst_Item = 0;			// 初期表示させるアイテムメニュー番号
	int iClient_Cnt = 0;			// 観戦者も含めた接続人数

	GetCurrentMap(sThis_map, sizeof(sThis_map));
	if (IsOnly_You)FormatEx(display, sizeof(display), "%T", "rank_you_Title", client);
	else FormatEx(display, sizeof(display), "%T", "rank_online_Title", client);
	hMenu.SetTitle(display);

	// 観戦者も含め、接続中プレイヤーのsteamIDを取得。
	if (IsOnly_You){
		GetClientAuthId(client, AuthId_Steam3, sOnline_steamID[1], sizeof(sOnline_steamID[]));
		for (int i = 2; i <= 8; i++) {
			FormatEx(sOnline_steamID[i], sizeof(sOnline_steamID[]), "x");		// クライアント以外はすべて"x"
		}
	}else{
		for (int i = 1; i <= 8; i++) {
			if (i <= MaxClients) {
				if (IsClientInGame(i) && !IsClientTimingOut(i)) {
					GetClientAuthId(i, AuthId_Steam3, sOnline_steamID[i], sizeof(sOnline_steamID[]));
					iClient_Cnt++;
				} else {
					FormatEx(sOnline_steamID[i], sizeof(sOnline_steamID[]), "x");		// 8名全員のIDをMySQLに渡すので、検索にヒットしないよう、x（バツというつもり）を代入しておく。
				}
			}else{
				FormatEx(sOnline_steamID[i], sizeof(sOnline_steamID[]), "x");		// MaxClientsが2名の場合もある。
			}
		}
	}

	// オンラインプレイヤーのマップ難易度ランキング"Rank"を取得。
	if (IsOnly_You){
		SQL_BindParamInt(m_hSQL_Get_Rank, 0, 1, false);
	}else{
		SQL_BindParamInt(m_hSQL_Get_Rank, 0, iClient_Cnt, false);
		}
	for (int i = 1; i <= 8; i++) SQL_BindParamString(m_hSQL_Get_Rank, i, sOnline_steamID[i], false);
	SQL_Execute(m_hSQL_Get_Rank);
	while (SQL_FetchRow(m_hSQL_Get_Rank)) {
		SQL_FetchString(m_hSQL_Get_Rank, 0, sReturn_map, sizeof(sReturn_map));
		SQL_FetchString(m_hSQL_Get_Rank, 1, sTemp, sizeof(sTemp));

		if (StrEqual(sReturn_map, sThis_map)){
			FormatEx(display, sizeof(display), "* %s", sTemp);		// 分かりやすく、現在のマップに * 印をつける
			iFirst_Item = hMenu.ItemCount - (hMenu.ItemCount % 7);		// * のついているページの先頭のアイテム番号
		}else{
			FormatEx(display, sizeof(display), "   %s", sTemp);
		}

		hMenu.AddItem(sReturn_map, display, ITEMDRAW_DISABLED);
	}
	if (hMenu.ItemCount == 0){
		FormatEx(display, sizeof(display), "  ( No data )");
		hMenu.AddItem("No_data", display, ITEMDRAW_DISABLED);
	}
	hMenu.ExitBackButton = true;
	hMenu.DisplayAt(client,iFirst_Item , MENU_TIME_FOREVER);
}



// ここは現状はCallback_Menu_this_mapと全く同じだ。（もしバージョンアップするとしたら、MENUのvote機能を利用したmap voteを実装したい。それを考慮し、別にしている。）
public int Callback_Menu_rank(Menu hMenu, MenuAction action, int param1, int param2){
	switch(action)
	{
		case MenuAction_DrawItem: {		// メニュー内の各項目ごとにそれぞれフック。ここで書式を切り替える。このcase 文がないと、最初のAddItemでスタイル指定をしても適用されない。
			int style;					// 書式を変更しない場合でも、現在のアイテムの書式を返さないと、エラーが発生する。
			char info[32];
			hMenu.GetItem(param2, info, sizeof(info), style);
			return style;
		}
		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack) Menu_main(param1, 0);
		}
		case MenuAction_End:delete hMenu;
	}
	return 0;
}



public void Menu_rank_all(int client){
	Menu hMenu = new Menu(Callback_Menu_rank_all, MENU_ACTIONS_ALL);
	char sThis_map[64];		// 現在プレイ中のマップ名。sMapと同じだが、練習時間にも対応するために、別で用意。
	char display[512];		// 表示する文字列
	char sReturn_map[64];	// MySQLからの返り値のmap名
	char sTemp[512];		// MySQLからの返り値の表示用文字列
	int iFirst_Item = 0;	// 初期表示させるアイテムメニュー番号


	GetCurrentMap(sThis_map, sizeof(sThis_map));
	FormatEx(display, sizeof(display), "%T", "rank_all_Title", client);
	hMenu.SetTitle(display);

	// 全プレイヤーのマップ難易度ランキング"Rank_All"を取得。
	SQL_Execute(m_hSQL_Get_Rank_All);
	while (SQL_FetchRow(m_hSQL_Get_Rank_All)) {
		SQL_FetchString(m_hSQL_Get_Rank_All, 0, sReturn_map, sizeof(sReturn_map));
		SQL_FetchString(m_hSQL_Get_Rank_All, 1, sTemp, sizeof(sTemp));
		if (StrEqual(sReturn_map, sThis_map)){
			FormatEx(display, sizeof(display), "* %s", sTemp);		// 分かりやすく、現在のマップに * 印をつける
			iFirst_Item = hMenu.ItemCount - (hMenu.ItemCount % 7);		// * のついているページの先頭のアイテム番号
		}else{
			FormatEx(display, sizeof(display), "   %s", sTemp);
		}
		hMenu.AddItem(sReturn_map, display, ITEMDRAW_DISABLED);
	}
	if (hMenu.ItemCount == 0){
		FormatEx(display, sizeof(display), "  ( No data )");
		hMenu.AddItem("No_data", display, ITEMDRAW_DISABLED);
	}
	hMenu.ExitBackButton = true;
	hMenu.DisplayAt(client,iFirst_Item , MENU_TIME_FOREVER);
}



// ここは現状はCallback_Menu_this_mapと全く同じだ。（もしバージョンアップするとしたら、MENUのvote機能を利用したmap voteを実装したい。それを考慮し、別にしている。）
public int Callback_Menu_rank_all(Menu hMenu, MenuAction action, int param1, int param2){
	switch(action)
	{
		case MenuAction_DrawItem: {		// メニュー内の各項目ごとにそれぞれフック。ここで書式を切り替える。このcase 文がないと、最初のAddItemでスタイル指定をしても適用されない。
			int style;					// 書式を変更しない場合でも、現在のアイテムの書式を返さないと、エラーが発生する。
			char info[32];
			hMenu.GetItem(param2, info, sizeof(info), style);
			return style;
		}
		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack) Menu_main(param1, 0);
		}
		case MenuAction_End:delete hMenu;
	}
	return 0;
}



public void Menu_delete(int client){
	Menu hMenu = new Menu(Callback_Menu_delete, MENU_ACTIONS_ALL);
	char display[128];

	FormatEx(display, sizeof(display), "%T", "delete_Title", client);
	hMenu.SetTitle(display);

	FormatEx(display, sizeof(display), "%T", "delete_no", client);
	hMenu.AddItem("delete_no", display, ITEMDRAW_DEFAULT);

	hMenu.AddItem("space", "",ITEMDRAW_SPACER);		// 行スペースの挿入。番号も1つ飛ばす。

	FormatEx(display, sizeof(display), "%T", "delete_yes", client);
	hMenu.AddItem("delete_yes", display, ITEMDRAW_DEFAULT);

	hMenu.ExitBackButton = true;
	hMenu.Display(client, MENU_TIME_FOREVER);
}



public int Callback_Menu_delete(Menu hMenu, MenuAction action, int param1, int param2){
	switch(action)
	{
		case MenuAction_DrawItem: {
			int style;
			char info[32];
			hMenu.GetItem(param2, info, sizeof(info), style);
			return style;
		}
		case MenuAction_Select: {
			char info[32];				// param1：クライアントインデックス, param2：GetMenuItemで使用するアイテム番号（いわゆる、並び順）
			hMenu.GetItem(param2, info, sizeof(info));
			if (StrEqual(info,"delete_yes"))		Delete_agreement(param1);
			else if (StrEqual(info,"delete_no"))	Menu_main(param1, 0);
		}
		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)Menu_main(param1, 0);
		}
		case MenuAction_End:delete hMenu;
	}
	return 0;
}



// クライアントの全プレイ記録の削除。
public void Delete_agreement(int client){
	char sDelete_steamID[32];

	GetClientAuthId(client, AuthId_Steam3, sDelete_steamID, sizeof(sDelete_steamID));
	SQL_BindParamString(m_hSQL_Delete_agreement, 0, sDelete_steamID, false);
	SQL_Execute(m_hSQL_Delete_agreement);

	for (int i = 1; i <= MaxClients; i++) {
		if (StrEqual(sOnRoundStart_steamID[i],sDelete_steamID )) {
			FormatEx(sOnRoundStart_name[i], sizeof(sOnRoundStart_name[]), "");
			FormatEx(sOnRoundStart_steamID[i], sizeof(sOnRoundStart_steamID[]), "");
			break;
		}
	}

	PrintToChat(client, "%t", "delete_agreement");
}
