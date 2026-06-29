#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

/*
 *	SM Bank
 *	by MaTTe (mateo10)
 */
 
 
#define DWDCOUNT 7
//static String:MoneyCount[ DWDCOUNT ][] = { "1000" , "2000" , "4000" , "8000", "16000"};

new LastMenuAction[ MAXPLAYERS + 1 ]; 
new TargetClientMenu[ MAXPLAYERS + 1 ];
new IHateFloods[ MAXPLAYERS + 1 ];

#define VERSION "3.0"

public Plugin:myinfo = 
{
	name = "SM Bank",
	author = "MaTTe, edit by Nican",
	description = "Player is allowed to put money in his bank, and take them out when he needs them",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};

new g_iAccount = -1;
 
#define ALLOWBANK 0
#define MAXBANK 1
#define DEPOSITFEE 2
#define TRANSFER 3
#define INTEREST 4
#define AUTOMONEY 5
#define PISTOLROUND 6
#define DBCONFIG 7
#define DBSAVE 8
#define MENUROUND 9
#define CSSTARTMONEY 10


new Handle:g_cvars[11];
new maxplayers;
new Handle:db = INVALID_HANDLE;

new BankMoney[ MAXPLAYERS + 1];
new DBid[ MAXPLAYERS + 1];

public OnPluginStart()
{
	CreateConVar("smbank_sql_version", VERSION, "SM Bank Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_cvars[ALLOWBANK] = CreateConVar("sm_bank_allow","1","Allow users to use the bank");
	g_cvars[TRANSFER] = CreateConVar("sm_bank_transfer","1","Allow users to transfer money to other users");
	g_cvars[MAXBANK] = CreateConVar("sm_bank_max","50000","Maximun Amount of money players are allowed to have in their bank");
	g_cvars[DEPOSITFEE] = CreateConVar("sm_bank_fee","250","Fee players must pay for each deposit");
	g_cvars[INTEREST] = CreateConVar("sm_bank_interest","5.0","% of interest players will get per round");
	g_cvars[PISTOLROUND] = CreateConVar("sm_bank_pistol","0","Set to 1 to block witdraw during pistol round");
	g_cvars[DBCONFIG] = CreateConVar("sm_bank_config","default","Set the database configuration");
	g_cvars[DBSAVE] = CreateConVar("sm_bank_save","2","1=disconnect, 2=round_start, 3=every change");
	g_cvars[MENUROUND] = CreateConVar("sm_bank_round","500","How much the plugin will round numbers to show on the menu");
	g_cvars[CSSTARTMONEY] = FindConVar("mp_startmoney");
	
	if( g_cvars[CSSTARTMONEY] == INVALID_HANDLE ){
        LogMessage("SMBANK: Could not find mp_startmoney. 800 will be used.");
    }
	
	HookConVarChange(g_cvars[DBCONFIG], BankConVarChanged);
	
	//g_cvars[AUTOMONEY] = CreateConVar("sm_bank_auto","0","Put 1 if money should be automacicly deposited/extracted");
	
	RegAdminCmd("sm_bankadd", Command_AddtoBank, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_bankset", Command_SetBank, ADMFLAG_CUSTOM4);

	LoadTranslations("plugin.smbank");

	RegConsoleCmd("deposit", Deposit);
	RegConsoleCmd("withdraw", WithDraw);
	RegConsoleCmd("bankstatus", BankStatus);
	RegConsoleCmd("bank", BankMenu);
	
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");

	HookEvent("round_start", EventRoundStart);	
	
	ConnectToMysql();
}

public BankConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[]){
    ConnectToMysql();
}

stock ConnectToMysql(){
    if(db != INVALID_HANDLE){
        LogMessage("[SM Bank] Disconnecting DB connection");
        CloseHandle(db);
        db = INVALID_HANDLE;
    }

    decl String:dbname[64];
    GetConVarString(g_cvars[DBCONFIG], dbname, 64);
    
    if(!SQL_CheckConfig( dbname )){
        LogMessage("[SM Bank] DB configuration '%s' does not exist, using default.", dbname );
        dbname = "default";
    }

    SQL_TConnect(OnSqlConnect, dbname);
}

public OnSqlConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{

    
    if (hndl == INVALID_HANDLE)
	{
		LogError("Database failure: %s", error);
	} else {
        db = hndl;
		
        decl String:buffer[1024];

        SQL_GetDriverIdent( SQL_ReadDriver(db), buffer, sizeof(buffer));
        new ismysql = StrEqual(buffer,"mysql", false) ? 1 : 0;
		
        if(ismysql == 1){
            Format(buffer, sizeof(buffer), "CREATE TABLE IF NOT EXISTS `sm_users` (`id` int(11) NOT NULL auto_increment,`steam` varchar(31) NOT NULL, `money` int(11) NOT NULL,PRIMARY KEY  (`id`),UNIQUE KEY `steam` (`steam`))");
        }else{
            Format(buffer, sizeof(buffer), "CREATE TABLE IF NOT EXISTS sm_users(id INTEGER PRIMARY KEY AUTOINCREMENT, steam TEXT UNIQUE, money INTEGER );");
        }
        
        SQL_FastQuery(db, buffer);		 
	}
}

public OnClientPostAdminCheck(client){
    DBid[ client ] = -1;

    decl String:AuthStr[32];
    
    if(IsFakeClient(client)){
        return;
    }
    
    if(!GetClientAuthString(client, AuthStr, 32)){
        return;        
    }

    decl String:MysqlQuery[512];
    
    Format(MysqlQuery, sizeof(MysqlQuery), "SELECT id, money FROM sm_users WHERE steam = '%s'", AuthStr);
    
    //LogMessage("%s", MysqlQuery);
    
    SQL_TQuery(db, T_NewClientConnected , MysqlQuery, GetClientUserId(client));
}

public T_NewClientConnected(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
    if ((client = GetClientOfUserId(data)) == 0)
	{
        return;
    }
	
    if (hndl == INVALID_HANDLE)
    {
		LogError("Query failed! %s", error);
    } else if (!SQL_GetRowCount(hndl)) {
        decl String:AuthStr[32], String:MysqlQuery[512]; 
        if(!GetClientAuthString(client, AuthStr, 32)){
            return;        
        }
	
		//Client no found, add him to the table
        Format(MysqlQuery, sizeof(MysqlQuery), "INSERT INTO sm_users(steam) VALUES('%s')", AuthStr);
        //LogMessage("%s", MysqlQuery);
		
        SQL_FastQuery(db, MysqlQuery);		
		
        return;
    }
	
    if(!SQL_FetchRow(hndl))
        return;
        
    DBid[ client ] =      SQL_FetchInt( hndl, 0);
    SetBankMoney(client, SQL_FetchInt( hndl, 1));
}


stock SaveClientInfo(client){
    decl String:MysqlQuery[512];

    if( DBid[ client ] == -1){
        decl String:AuthStr[32]; 
        if(!GetClientAuthString(client, AuthStr, 32)){
            return;        
        }
    
        Format(MysqlQuery, sizeof(MysqlQuery), "UPDATE sm_users SET money = %d WHERE steam = '%s'", BankMoney[ client ], AuthStr);
    } else {
        Format(MysqlQuery, sizeof(MysqlQuery), "UPDATE sm_users SET money = %d WHERE id = %d", BankMoney[ client ], DBid[ client ]);    
    }
    //LogMessage("%s", MysqlQuery);
    SQL_FastQuery(db, MysqlQuery);
}



public OnMapStart(){
	maxplayers = GetMaxClients();
}

public Action:Command_AddtoBank(client, args){
	if (args < 2){
		ReplyToCommand(client, "[SM] Usage: sm_bankadd <#userid|name> <money>");
		return Plugin_Handled;
	}
	
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	new target = FindTarget(client, arg, true , false);
	if (target == -1)
		return Plugin_Handled;

	decl String:moneys[12];
	GetCmdArg(2, moneys, sizeof(moneys));
	new money = StringToInt(moneys);	
	
	SetBankMoney(target, GetBankMoney(target) + money);
	
	PrintToChatAll("[NC] \x04[SM Bank]\x01 Admin has changed your money");

	return Plugin_Handled;
}

public Action:Command_SetBank(client, args){
	if (args < 2){
		ReplyToCommand(client, "[SM] Usage: sm_bankset <#userid|name> <money>");
		return Plugin_Handled;
	}
	
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	new target = FindTarget(client, arg, true , false);
	if (target == -1)
		return Plugin_Handled;

	decl String:moneys[12];
	GetCmdArg(2, moneys, sizeof(moneys));
	new money = StringToInt(moneys);	
	
	SetBankMoney(target, money);
	
	PrintToChatAll("[NC] \x04[SM Bank]\x01 Admin has changed your money"); 

	return Plugin_Handled;
}

stock SetBankMoney(client, money){
    new maxmoney = GetConVarInt(g_cvars[MAXBANK]);
    
    if(maxmoney > 0 && money > maxmoney) money = maxmoney;
    if(money < 0) money = 0;
    
    BankMoney[ client ] = money;
    
    if(GetConVarInt(g_cvars[DBSAVE]) == 3){
        SaveClientInfo(client);
    }
}

stock GetBankMoney(client){
    return BankMoney[ client ];
}

public OnClientDisconnect(client){
    if(GetConVarInt(g_cvars[DBSAVE]) <= 2){
        SaveClientInfo(client);
    }
}


public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast){
	
	new maxmoney, curmoney, bool:ShouldSave;
	decl String:MoneyGain[32];
	
	maxmoney = GetConVarInt(g_cvars[MAXBANK]);
	//auto = GetConVarBool(g_cvars[AUTOMONEY]);
	
	ShouldSave = (GetConVarInt(g_cvars[DBSAVE]) == 2);
	
	for(new i = 1; i <= maxplayers ; i ++){
		if(!IsClientInGame(i)) continue;
		//No spectators...
		if(GetClientTeam(i) <= 1) continue;
		
		if(IHateFloods[i]){
		 	PrintToChat(i, "%t", "Available commands", "\x04", "\x01");
			IHateFloods[i]=false;
		}
		
		if(ShouldSave){
            SaveClientInfo(i);
        }
		
		//if(auto){
		//	WithDrawClientMoney(client, "all");
		//}
		
		//PrintToChat(i, "Adding interest to you!");
		
		curmoney = GetBankMoney(i);
		
		curmoney += RoundFloat(FloatMul( float (curmoney) , GetConVarFloat(g_cvars[INTEREST]) / 100.0 ));
		
		
		if(maxmoney > 0 && curmoney > maxmoney ){
			curmoney = maxmoney;
		}
		
		//PrintToChat(i, "Your gain is: %d", gain);
		
		if(curmoney != GetBankMoney(i)){
    		IntToMoney(curmoney - GetBankMoney(i), MoneyGain, 32);
    		PrintToChat(i, "%t", "Interested gained", "\x04", "\x01", MoneyGain);
    		SetBankMoney(i, curmoney);
		}
		
		//PrintToChat(i, "loop finished!");
	}
}

public Action:BankMenu(client, args){
	if (!GetConVarInt(g_cvars[ALLOWBANK])){
		PrintToChat(client, "%t", "Bank Disabled", "\x04", "\x01");
		return Plugin_Handled;
	}
 
	new Handle:menu = CreateMenu(MenuHandler1);
	SetMenuTitle(menu, "Bank:");
	AddMenuItem(menu, "dep", "Deposit");
	AddMenuItem(menu, "wit", "Withdraw");
	AddMenuItem(menu, "bal", "Balance");
	AddMenuItem(menu, "tran", "Transfer");
	
	DisplayMenu(menu, client, 20);
 
	return Plugin_Handled;
}

public MenuHandler1(Handle:menu, MenuAction:action, client, param2)
{
	if (!GetConVarInt(g_cvars[ALLOWBANK])){
		PrintToChat(client, "%t", "Bank Disabled", "\x04", "\x01");
		CloseHandle(menu);
		return;
	}
 
	/* Either Select or Cancel will ALWAYS be sent! */
	if (action == MenuAction_Select)
	{
	 	LastMenuAction[client] = param2;
		switch( param2 ){
			case 0,1: {
				
				new Handle:menu2 = CreateMenu(DepositWithMenu);
				if(param2 == 0){
                    SetMenuTitle(menu2, "Bank - Deposit:");
					
                    new maxmoney = GetConVarInt(g_cvars[MAXBANK]);
                    new bankmoney = GetBankMoney(client);
                    new curmoney = GetMoney(client);
					
                    new maxdeposit = maxmoney - bankmoney;
					
                    if(curmoney == 0){
                        PrintToChat(client, "[SM Bank] You don't have any money!");
                        CloseHandle(menu2);
                        return;
                    }
					
                    if(maxdeposit == 0){
                        PrintToChat(client, "[SM Bank] Your bank is full!");
                        CloseHandle(menu2);
                        return;
                    }
                    
                    if(maxdeposit > curmoney) maxdeposit = curmoney;
					
                    AddMoneyItems(menu2, maxdeposit);
				}else{
                    SetMenuTitle(menu2, "Bank - Withdraw:");
                    new maxamount = 16000 - GetMoney(client);
                    new curmoney = GetBankMoney(client);
					
                    if(maxamount == 0){
                        PrintToChat(client, "[SM Bank] You can not hold more money!");
                        CloseHandle(menu2);
                        return;
                    }
                    
                    if(curmoney == 0){
                        PrintToChat(client, "\x04[SM Bank]\x01 You don't have any money in your bank!");
                        CloseHandle(menu2);
                        return;
                    }
                    
                    if(maxamount > curmoney) maxamount = curmoney;
					
                    AddMoneyItems(menu2, maxamount);
				}
				
				DisplayMenu(menu2, client, 20);
			}
			case 2:{
				ShowBankStatus(client);
			}
			case 3:{
				if (!GetConVarInt(g_cvars[TRANSFER])){
						PrintToChat(client, "%t", "No Transfer", "\x04", "\x01");
						return;
				}
				//I can not belive I am doing String:id
				new Handle:menu2 = CreateMenu(TransferMenu), String:name[64], String:id[8];
				SetMenuTitle(menu2, "Bank - Tranfer:");
				
				new count =0;
				for(new i = 1; i <= maxplayers ; i ++){			 	
					if(!IsClientInGame(i)) continue;
					if(client == i) continue;
					if(IsFakeClient(i)) continue;
					
					//PrintToChat(client, "Checking passed: %d", i);	
					
					count++;
				 	
				 	GetClientName(i, name, sizeof(name));
				 	IntToString(i, id, sizeof(id));
				 	AddMenuItem(menu2, id, name);
				}
				//PrintToChat(client, "Players found: %d", count);	
				
				if(count == 0){
					PrintToChat(client, "There is not one connected in the server");
					CloseHandle(menu2);
					return;
				}
				
				DisplayMenu(menu2, client, 20);
			}
		}
	}
 
	/* If the menu has ended, destroy it */
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

stock RoundOff(num, dif){
    new offset = num % dif;
	
    if(offset > (dif/2)){
        return num + dif - offset;
    }
	
    return num - offset;
}

public AddMoneyItems(Handle:menu2, Money){
    new String:dummy[32], String:dummy2[32];
    new testint;
    
    new PartialMoney = Money / DWDCOUNT;
    new RoundTo = GetConVarInt(g_cvars[MENUROUND]);
    new LastValue;
	
    for(new i=1; i< DWDCOUNT; i++){
        testint = RoundOff(PartialMoney * i, RoundTo);
        
        if(testint > Money) testint = Money;
        if(testint == LastValue) continue;
        
        LastValue = testint;
        
        IntToMoney( testint , dummy , sizeof(dummy) );
        IntToString( testint, dummy2, sizeof(dummy2) );
                
        AddMenuItem(menu2, dummy2, dummy);
        
	 	/*testint = StringToInt( MoneyCount[i] );
	 	if(testint > 0){
		 	IntToMoney( testint , dummy , 32);
			AddMenuItem(menu2, MoneyCount[i], dummy);
		}
		*/
    }
    
    IntToMoney( Money, dummy , sizeof(dummy) );
    IntToString( Money, dummy2, sizeof(dummy2) );
                
    AddMenuItem(menu2, dummy2, dummy);
    
	
    //AddMenuItem(menu2, "all", "All");
}

public DepositWithMenu(Handle:menu, MenuAction:action, client, param2)
{
	if (!GetConVarInt(g_cvars[ALLOWBANK])){
		PrintToChat(client, "%t", "Bank Disabled", "\x04", "\x01");
		CloseHandle(menu);
		return;
	}
 
	/* Either Select or Cancel will ALWAYS be sent! */
	if (action == MenuAction_Select)
	{
		new String:info[32];
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
		
		if(!found)
			return;		
		
		switch( LastMenuAction [ client ]){
			case 0: {
				DepositClientMoney( client, info );
			}
			case 1: {
				WithDrawClientMoney( client, info );
			}
			case 3:{
				if (!GetConVarInt(g_cvars[TRANSFER])){
					PrintToChat(client, "%t", "No Transfer", "\x04", "\x01");
					CloseHandle(menu);
					return;
				}
				TransferClientMoney( client, TargetClientMenu[ client ], info);		
			}
		}
	} else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public TransferMenu(Handle:menu, MenuAction:action, client, param2){
	if (!GetConVarInt(g_cvars[ALLOWBANK])){
		PrintToChat(client, "%t", "Bank Disabled", "\x04", "\x01");
		CloseHandle(menu);
		return;
	}
	
	if (!GetConVarInt(g_cvars[TRANSFER])){
		PrintToChat(client, "%t", "No Transfer", "\x04", "\x01");
		CloseHandle(menu);
		return;
	}
 
	/* Either Select or Cancel will ALWAYS be sent! */
	if (action == MenuAction_Select)
	{
		new String:info[32];		
		if(!GetMenuItem(menu, param2, info, sizeof(info)))
			return;
			
		TargetClientMenu[ client ] = StringToInt(info);
		
		if(!IsClientConnected( TargetClientMenu[ client ] )){
			PrintToChat(client, "%t", "False Target", "\x04", "\x01");
			CloseHandle(menu);
			return;			
		}
		
		
		GetClientName(TargetClientMenu[ client ] , info, sizeof(info));
				
		new Handle:menu2 = CreateMenu(DepositWithMenu);
		SetMenuTitle(menu2, "Tranfer money to: %s", info);
		
		
		new targetmoney = GetBankMoney(TargetClientMenu[ client ]);
		new clientmoney = GetBankMoney(client);
		new maxmoney = GetConVarInt(g_cvars[MAXBANK]);
		
		new maxmenu = maxmoney - targetmoney;
		if(maxmenu > clientmoney) maxmenu = clientmoney;   
		
				
		AddMoneyItems(menu2, maxmenu);
			
		DisplayMenu(menu2, client, 20);
	
	} else if (action == MenuAction_End){
		CloseHandle(menu);
	} 
}

public Action:Deposit(client, args)
{
	if (!GetConVarInt(g_cvars[ALLOWBANK])){
		PrintToChat(client, "%t", "Bank Disabled", "\x04", "\x01");
		return Plugin_Handled;
	} 
	
	if(args < 1)
	{
		PrintToChat(client, "%t", "Deposit usage", "\x04", "\x01");
		return Plugin_Handled;
	}

	new String:szCmd[12];
	GetCmdArg(1, szCmd, sizeof(szCmd));
	
	DepositClientMoney(client, szCmd);

	return Plugin_Handled;
}

public TransferClientMoney( client, target, String:amount[] ){
	if(!IsClientConnected(client))
		return;
	if(!IsClientConnected(target)){
		PrintToChat(client, "%t", "No Transfer", "\x04", "\x01");
		return;
	}
	if (!GetConVarInt(g_cvars[TRANSFER])){
		PrintToChat(client, "%t", "False Target", "\x04", "\x01");
		return;
	}
	
	//LogMessage("Transfear: %d %d %s", client, target, amount);
	
	new deposit,money, maxmoney, targetmoney;
	
	money = GetBankMoney(client);
	targetmoney = GetBankMoney(target);
	maxmoney = GetConVarInt(g_cvars[MAXBANK]);
	
	if(StrEqual(amount, "all"))
		deposit = money;
	else{
		deposit = StringToInt(amount);
		if(deposit > money){
    		PrintToChat(client, "%t", "Deposit not enough money", "\x04", "\x01");
    		return;
    	}
	}
		
	if(deposit == 0){ return; }
		
	//LogMessage("Transfear2: %d %d %d %d", deposit,money, maxmoney, targetmoney);
		
	//LogMessage("client: %d | Target: %d", client, target);
	//LogMessage("money: %d | targetmoney: %d | deposit: %d | maxmoney: %d", money, targetmoney, deposit, maxmoney);
	
	new String:name[32], String:targetname[32], String:depositstr[12];
	
	GetClientName(client , name, sizeof(name));
	GetClientName(target , targetname, sizeof(targetname));
	
	/*if(maxmoney > 0 && (targetmoney + deposit) > maxmoney){
	 	deposit = maxmoney - targetmoney;
	 	if(deposit <= 0){
			PrintToChat(client, "%t" ,"TargetTotalLimit", "\x04", "\x01", targetname);
			return;
		}
		IntToMoney(deposit, depositstr, 12);
		PrintToChat(client, "%t" ,"TargetLimit", "\x04", "\x01", targetname, depositstr);
	}*/
	
	targetmoney += deposit;
	money -= deposit;
	
	if(maxmoney > 0){
        if(targetmoney > maxmoney ){
            new difference = targetmoney - maxmoney;
            
            targetmoney = maxmoney;
            
            money += difference;
        }else if(targetmoney == maxmoney ){
            PrintToChat(client, "%t" ,"TargetTotalLimit", "\x04", "\x01", targetname);
            return;  
        }
    }
	
	IntToMoney( GetBankMoney(client) - money ,depositstr, 12);
	
	SetBankMoney(client, money);
	SetBankMoney(target, targetmoney);	

	PrintToChat(target, "%t", "TargetDeposited","\x04", "\x01", name, depositstr);
	PrintToChat(client, "%t", "ClientTargetDeposited","\x04", "\x01", targetname, depositstr);
}

public DepositClientMoney(client, String:szCmd[]){
    new bankmoney, feemoney, maxmoney, money, deposit;
    decl String:feestr[12], String:depositstr[12];
	
    money = GetMoney(client);
	
    if(StrEqual(szCmd, "all"))
		deposit = money;
    else
		deposit = StringToInt(szCmd);
	
    if(deposit > money){
		PrintToChat(client, "%t", "Deposit not enough money", "\x04", "\x01");
		return;
    }

    bankmoney = GetBankMoney(client);
    feemoney = GetConVarInt(g_cvars[DEPOSITFEE]); 
    maxmoney = GetConVarInt(g_cvars[MAXBANK]);
	
    IntToMoney(feemoney, feestr, 12);

    if(deposit < feemoney){
		PrintToChat(client, "%t", "You need at least", feestr ,"\x04", "\x01");
		return;
    }
	
    deposit -= feemoney;
    bankmoney += deposit;
	
    if(maxmoney > 0 && bankmoney > maxmoney){
		PrintToChat(client, "%t", "Bank Full", maxmoney, "\x04", "\x01");
		deposit = bankmoney - maxmoney;
		bankmoney = maxmoney;
		if(deposit == 0)
			return;
    }
	
    SetBankMoney(client, bankmoney);
    SetMoney(client, money - deposit - feemoney);
	
	//SetMoney(client, -deposit - feemoney + money);
    IntToMoney(deposit, depositstr, 12);
	

    PrintToChat(client, "%t", "Deposit successfully", depositstr, feestr ,"\x04", "\x01");
}

public Action:WithDraw(client, args)
{
	if (!GetConVarInt(g_cvars[ALLOWBANK])){
		PrintToChat(client, "%t", "Bank Disabled", "\x04", "\x01");
		return Plugin_Handled;
	}
	
	if(args < 1)
	{
		PrintToChat(client, "%t", "Withdraw usage", "\x04", "\x01");
	}

	new String:szCmd[12];
	GetCmdArg(1, szCmd, sizeof(szCmd));
	
	WithDrawClientMoney(client, szCmd);

	return Plugin_Handled;
}

public WithDrawClientMoney(client, String:szCmd[]){
	if (GetConVarInt(g_cvars[PISTOLROUND]) == 1){
		if(IsPistolRound()){
			PrintToChat(client, "%t", "PistolRoundBlocked", "\x04", "\x01");
			return;
		}
	}	
 
 	new getmoney = GetBankMoney(client);
 	new AmountToWith;
	if(StrEqual(szCmd, "all"))
	{
		new iBalance = 16000 - GetMoney(client);

		if(getmoney < iBalance)
		{
		 	AmountToWith = getmoney;		
		}
		else
		{
		 	AmountToWith = iBalance;
		}
	}
	else
	{
		new iMoney = StringToInt(szCmd);

		if(getmoney < iMoney)
		{
			PrintToChat(client, "%t", "Withdraw not enough money", "\x04", "\x01");
			return; 
		}

		if(GetMoney(client) + iMoney <= 16000)
		{
		 	AmountToWith = iMoney;			
		}
		else
		{
			PrintToChat(client, "%t", "Withdraw max error", "\x04", "\x01");
			return;
		}
	}
	
	SetMoney(client, AmountToWith, true);
	SetBankMoney(client, getmoney - AmountToWith);
	
	
	new String:WithStr[12];
	IntToMoney(AmountToWith, WithStr, 12);
	
	PrintToChat(client, "%t", "Withdraw successfully", WithStr, "\x04", "\x01");
}

public Action:BankStatus(client, args)
{
	ShowBankStatus(client);
	return Plugin_Handled;
}

stock ShowBankStatus(client){
	new String:WithStr[12];
	new money;
	money = GetBankMoney(client);
	IntToMoney( money , WithStr, 12);
 	//PrintToChat(client, "%d -- %s", money, WithStr); 	
	PrintToChat(client, "%t", "Bankstatus", WithStr, "\x04", "\x01");
}

stock SetMoney(client, amount, add = false){
	if(add)
		amount += GetMoney(client);
	if(amount > 16000) amount = 16000;
	if(amount < 0) amount = 0;
	
	SetEntData(client,g_iAccount,amount,4,true);
}

stock GetMoney(client){
	return GetEntData(client,g_iAccount,4);
}

stock IntToMoney(theint, String:result[], maxlen){
 	new slen, pointer, String:intstr[maxlen], bool:negative;
 	
 	negative = theint < 0;
 	if(negative) theint *= -1;
 	
 	IntToString(theint, intstr, maxlen);
 	slen = strlen(intstr);
 	
 	theint = slen % 3;
 	if(theint == 0) theint = 3;
	Format(result,theint + 1, "%s", intstr);
	
	slen -= theint;
	pointer = theint + 1;
	for(new i = theint; i <= slen ; i += 3){
	 	pointer += 4;
		Format(result, pointer, "%s,%s",result, intstr[i]);
	}
 	
 	if(negative)
 		Format(result, maxlen, "$-%s", result);
 	else
 		Format(result, maxlen, "$%s", result);
}

public OnClientAuthorized(id){
	IHateFloods[id] = true;
}

stock bool:IsPistolRound(){
	new i, startmoney;
	
	if( g_cvars[CSSTARTMONEY] != INVALID_HANDLE )
	   startmoney = GetConVarInt( g_cvars[CSSTARTMONEY] );
	else
	   startmoney = 800;
	
	
	for(i=1; i<=maxplayers; i++){
	 	if(IsClientInGame(i))
			if(GetMoney(i) > startmoney)
				return false;
	}
	return true;
}
