#include <sourcemod>

#define MAX_LANGS 100
#define MAX_LANG_LENGTH 100
#define LANG_SEPARATOR ";"
#define FOLDER "gamedata/"
#define FILE_PREFIX "lc_"
#define FILE_SUFFIX ".txt"
#define FILEPATH_LENGTH 1024
#define INDEX_COUNT 30
#define MAX_WORD_LENGHT 100
#define MAX_WORD_COUNT 100
#define TRANSLATION_FILE "language_check.phrases"
#define TRANSLATION_KICK "Language Kick"
#define TRANSLATION_WARN "Language Warn"
#define TRANSLATION_WARN_COUNT "Language Warn Counter"
#define RESET_COMMAND "sm_lc_reset_player"
#define REINIT_COMMAND "sm_init_dict"
#define LC_VERSION "1.1.4.1"

#undef REQUIRE_PLUGIN
#include <updater>

#define UPDATE_URL    "http://gaming.comhix.de/sm/updater.php/lc/info.txt"

/**
 * Plugin public information.
 */
public Plugin:myinfo =
{
	name = "Language Checker",
	author = "NoZomIBK",
	description = "Check Chat Messages for allowed languages",
	version = LC_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=203206"
};

enum Language{
	indexes[INDEX_COUNT],
	String:lang[MAX_LANG_LENGTH],
	Handle:file,
	String:filepath[FILEPATH_LENGTH],
};

enum PlayerStat{
	userid,
	wordcount,
	warnings,
	Float:lastRatio,
	Float:ratio,
};

new Handle:sm_lc_languages = INVALID_HANDLE;
new Handle:sm_lc_enabled = INVALID_HANDLE;
new Handle:sm_lc_logging = INVALID_HANDLE;
new Handle:sm_lc_min_wordcount = INVALID_HANDLE;
new Handle:sm_lc_max_wordcount = INVALID_HANDLE;
new Handle:sm_lc_min_warnings = INVALID_HANDLE;
new Handle:sm_lc_max_warnings = INVALID_HANDLE;
new Handle:sm_lc_warn_ratio = INVALID_HANDLE;
new Handle:sm_lc_kick_ratio = INVALID_HANDLE;
new Handle:sm_lc_kick = INVALID_HANDLE;
new Handle:sm_lc_use_index = INVALID_HANDLE;
new Handle:sm_lc_version = INVALID_HANDLE;

new languageCount=0;
new maxWords=100;
new languages[MAX_LANGS][Language];
new players[MAXPLAYERS][PlayerStat];
new bool:useIndex=true;

public OnPluginStart(){
	initHooks();
	initCvars();
	LoadTranslations(TRANSLATION_FILE);
	
	if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL)
    }

	for(new i=1;i<MAXPLAYERS;i++){
		resetPlayer(i);
	}
}

public OnConfigsExecuted(){
	initDictionaries();
}

initHooks(){
	RegAdminCmd(REINIT_COMMAND, CommandReinitDictionaries, ADMFLAG_SLAY);
	RegAdminCmd(RESET_COMMAND,CommandResetPlayer,ADMFLAG_SLAY);
	HookEvent("player_say",handler_player_say);
}

initCvars(){
	decl String:languages_path[255];
	decl String:languages_desc[500];
	decl String:langString[50];
	
	BuildPath(Path_SM,languages_path,sizeof(languages_path),"%s%s<lang>%s",FOLDER,FILE_PREFIX,FILE_SUFFIX);
	Format(languages_desc,sizeof(languages_desc),"Language Files to search for Words. Language File: %s",languages_path);	
	Format(langString, sizeof(langString), "en_us%sen_gb%slolz", LANG_SEPARATOR, LANG_SEPARATOR);
	sm_lc_languages = CreateConVar("sm_lc_languages",langString,languages_desc);
	sm_lc_enabled = CreateConVar("sm_lc_enabled","1","Enables Language Check");
	sm_lc_logging = CreateConVar("sm_lc_logging","1","Enables ConsoleLogging for Language Check, higher value for more verbose",0,true,0.0,true,3.0);
	sm_lc_min_wordcount = CreateConVar("sm_lc_min_wordcount","20","Minimal amount of words before validationcheck runs",0,true,1.0);
	sm_lc_max_wordcount = CreateConVar("sm_lc_max_wordcount","100","Maximal amount of words to calculate ratio",0,true,1.0);
	sm_lc_warn_ratio = CreateConVar("sm_lc_warn_ratio","0.5","Ratio of bad words to start warnings",0,true,0.0,true,1.0);
	sm_lc_kick_ratio = CreateConVar("sm_lc_kick_ratio","0.8","Ratio of bad words to kick",0,true,0.0,true,1.0);
	sm_lc_min_warnings = CreateConVar("sm_lc_min_warnings","3","Minimum amount of warnings before kick");
	sm_lc_max_warnings = CreateConVar("sm_lc_max_warnings","3","Amount of Warnings to be kicked. Needs sm_lc_kick 2");
	sm_lc_kick = CreateConVar("sm_lc_kick","1","0: Warn, 1: kick by Ratio, 2: kick by max warnings",0,true,0.0,true,2.0);
	sm_lc_use_index = CreateConVar("sm_lc_use_index","1","Create an index, maybe longer startup, but could be faster on searching. Only ASCII is used in index. Dictionaryfile must be lexical ordered, upper/lower does not matter like: (aAbBCc)");
		
	HookConVarChange(sm_lc_use_index,useIndexChanged);
	HookConVarChange(sm_lc_languages,useIndexChanged);
	HookConVarChange(sm_lc_min_wordcount,minMaxWordcountChanged);
	HookConVarChange(sm_lc_max_wordcount,minMaxWordcountChanged);
	
	AutoExecConfig(true,"plugin_language_check");
	
	//Public Cvar
	sm_lc_version=CreateConVar("sm_lc_version",LC_VERSION,"Language Checker plugin version",FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	SetConVarString(sm_lc_version,LC_VERSION);
	HookConVarChange(sm_lc_version,versionChanged);
}

/**
 * 
 * INITIALIZATION
 * 
 */

/**
 * init all dictionary files
 */
initDictionaries(){
	decl String:langs[MAX_LANG_LENGTH];
	GetConVarString(sm_lc_languages,langs,sizeof(langs));
	decl String:loclang[MAX_LANGS][MAX_LANG_LENGTH];
	
	new count=ExplodeString(langs,LANG_SEPARATOR,loclang,sizeof(loclang),sizeof(loclang[]));
	
	languageCount=0;
	for(new i=0;i<count;i++){
		TrimString(loclang[i]);
		initDictionary(loclang[i]);
	}
}

/**
 * init specified dictionary
 */
initDictionary(String:loclang[]){
	decl String:lFilepath[FILEPATH_LENGTH];
	BuildPath(Path_SM,lFilepath,FILEPATH_LENGTH,"%s%s%s%s",FOLDER,FILE_PREFIX,loclang,FILE_SUFFIX);
	
	debuglogging(1, "\"%s\" init",lFilepath);
	
	if(FileExists(lFilepath)){
		strcopy(languages[languageCount][lang],MAX_LANG_LENGTH,loclang);
		languages[languageCount][file] = OpenFile(lFilepath,"r");
		strcopy(languages[languageCount][filepath],FILEPATH_LENGTH,lFilepath);
		
		if(languages[languageCount][file] == INVALID_HANDLE){
			debuglogging(1,  "\"%s\" init failed, cannot open file",loclang);
			return;
		}
		if(GetConVarBool(sm_lc_use_index)){
			createFileIndex(languageCount);
		}
		
		languageCount++;
		debuglogging(1,  "\"%s\" init finished",loclang);
	}
	else{
		debuglogging(1, "\"%s\" init failed",loclang);
	}
}

createFileIndex(languageIndex){
	new lastIndex=-1;
	
	while(!IsEndOfFile(languages[languageIndex][file])){
		decl String:first[1024];
		new position=FilePosition(languages[languageIndex][file]);
		
		if(ReadFileLine(languages[languageIndex][file],first,1024)){
			if(IsCharAlpha(first[0])){
				if(IsCharUpper(first[0])){
					first[0] = CharToLower(first[0]);
				}
				new index=first[0];
				index -= 'a';
				
				//new start char
				if(index > lastIndex){
					debuglogging(2,"Found %c from %s at Position %d in %s",first[0],first,position,languages[languageIndex][lang]);
					languages[languageIndex][indexes][index] = position;
					lastIndex = index;
					
					if(index == INDEX_COUNT-1){
						break;
					}
				}
			}
			else if(IsCharMB(first[0])){
				debuglogging(3,"%c is multibyte in %s",first[0],languages[languageIndex][lang]);
			}
			else{
				debuglogging(2,"%c is no charalpha in %s",first[0],languages[languageIndex][lang]);
			}
		}
	}
}

/**
 * 
 * SEARCH
 * 
 */

trimPunctuation(String:word[]){
	for(new i=strlen(word)-1;i>0;i--){
		if(IsCharAlpha(word[i]) || IsCharMB(word[i])){
			break;
		}
		word[i]=0;
	}
}

bool:seekWordInLang(languageIndex,String:word[]){
	debuglogging( 2,"Seek \"%s\" in %s. Using index: %d",word,languages[languageIndex][lang],useIndex);
	
	if(IsCharUpper(word[0])){	
		word[0] = CharToLower(word[0]);
	}
		
	/*
	 * Finding start and end index
	 */
	new nextIndex=0;
	new skipBytes=0;
	
	if(useIndex){
		new index=word[0];
		index -= 'a';
				
		skipBytes = languages[languageIndex][indexes][index];
				
		for(new i=index+1;i<INDEX_COUNT;i++){
			nextIndex = languages[languageIndex][indexes][i];
			if(nextIndex != 0){
				//nextIndex found
				break;
			}
		}
	}
		
	if(nextIndex <= skipBytes){
		nextIndex = FileSize(languages[languageIndex][filepath]);
		debuglogging(2,"nextindex = filesize: %d file: %s",nextIndex,languages[languageIndex][filepath]);
	}
	
	debuglogging(2,"Search from %d to %d",skipBytes,nextIndex);
		
	/*
	 * Search file
	 */
	FileSeek(languages[languageIndex][file],skipBytes,0);
	//FileSeek(languages[languageIndex][file],0,0);
		
	while(FilePosition(languages[languageIndex][file]) < nextIndex){
	//while(!IsEndOfFile(languages[languageIndex][file])){
		decl String:buffer[MAX_WORD_LENGHT];
		if(ReadFileLine(languages[languageIndex][file],buffer,MAX_WORD_LENGHT)){
			// remove trailing new line
			TrimString(buffer);

			if(StrEqual(buffer,word,false)){
				return true;
			}
		}			
	}
	//nothing found
	return false;
}

seekInLang(languageIndex,String:text[][],pwordcount,bool:wordValid[]){
	new bool:disableIndex=false;
	
	for(new i=0;i<pwordcount;i++){
		if(wordValid[i]){
			//ignore already found words
			continue;
		}
		else if(IsCharMB(text[i][0])){
			//MB Chars are not indexed
			disableIndex=true;
		}
		else if(!IsCharAlpha(text[i][0])){
			//ignore commands and smileys and shit
			wordValid[i]=true;
			continue;
		}
		
		trimPunctuation(text[i]);
		
		new bool:oldUseIndex=useIndex;
		if(disableIndex){
			useIndex=false;
		}
		if(seekWordInLang(languageIndex,text[i])){
			debuglogging( 2,"\"%s\" found",text[i]);
			wordValid[i]=true;
		}
		if(disableIndex){
			useIndex=oldUseIndex;
		}
	}
}

/**
 * 
 * COMMAND CALLBACKS
 * 
 */

public Action:CommandReinitDictionaries(client, args){
	initDictionaries();
	return Plugin_Handled;
}

public Action:handler_player_say(Handle:event, const String:name[], bool:dontBroadcast){
	if(languageCount <= 0 || !GetConVarBool(sm_lc_enabled)){
		return Plugin_Continue;
	}
	
	decl String:text[255];
	new lwordcount=0;
	decl String:words[MAX_WORD_COUNT][MAX_WORD_LENGHT];
	GetEventString(event,"text",text,255);
	lwordcount = ExplodeString(text," ",words,sizeof(words),sizeof(words[]));
	
	lwordcount = RemoveEmptyStrings(words,lwordcount);

	new found=0;
	new bool:wordValid[lwordcount];
	
	for(new i=0;i<languageCount;i++){
		seekInLang(i,words,lwordcount,wordValid);
	}
	
	for(new i=0;i<lwordcount;i++){
		if(wordValid[i]){
			found++;
		}
	}

	debuglogging(1,  "\"%s\" said: \"%s\" %d of %d words recognized",name,text,found,lwordcount);
	
	updateUserStat(GetEventInt(event,"userid"),found,lwordcount);
	return Plugin_Continue;
}

public Action:CommandResetPlayer(client,args){
	if(args < 1){
		ReplyToCommand(client,"usage: %s <id or name>",RESET_COMMAND);
		return Plugin_Handled;
	}
	
	decl String:targetStr[64];
	GetCmdArg(1,targetStr, sizeof(targetStr));
	
	new target = FindTarget(client, targetStr, true, false);
	
	if(target != -1){
		resetPlayer(target);
	}
	
	return Plugin_Handled;
}

public useIndexChanged(Handle:cvar, const String:oldVal[], const String:newVal[]){
	//useIndex or languages changed
	//have to use index now, reinit dicts
	initDictionaries();
}

public minMaxWordcountChanged(Handle:cvar, const String:oldVal[], const String:newVal[]){
	if(GetConVarInt(sm_lc_max_wordcount) <= GetConVarInt(sm_lc_min_wordcount)){
		SetConVarInt(sm_lc_max_wordcount,GetConVarInt(sm_lc_min_wordcount)*2);
	}
	maxWords = GetConVarInt(sm_lc_max_wordcount);
}

public versionChanged(Handle:cvar, const String:oldVal[], const String:newVal[]){
	if(!StrEqual(newVal,LC_VERSION)){
		SetConVarString(sm_lc_version,LC_VERSION);
	}
}

/**
 * 
 * USER STATISTIC
 * 
 */

updateUserStat(puserid,maxFound,lwordcount){
	new clientId = GetClientOfUserId(puserid);

	players[clientId][ratio] *= float(maxWords)/float((maxWords+lwordcount));
	players[clientId][ratio] += float(maxFound)/float((maxWords+lwordcount));
	players[clientId][wordcount] += lwordcount;
	
	debuglogging( 1, "%f ratio, %d wordcount, %d warnings",1-players[clientId][ratio],players[clientId][wordcount],players[clientId][warnings]);
	
	checkPlayerViolation(clientId);
}

checkPlayerViolation(clientId){
	if(players[clientId][wordcount] < GetConVarInt(sm_lc_min_wordcount)){
		return;
	}
	
	debuglogging( 1,"%f ratio, %f kick, %f warn",1-players[clientId][ratio],GetConVarFloat(sm_lc_kick_ratio),GetConVarFloat(sm_lc_warn_ratio));
	
	// he seems to do better
	if(players[clientId][ratio]>players[clientId][lastRatio]){
		players[clientId][lastRatio]=players[clientId][ratio];
		return;
	}
	
	new bool:kick;
	new kickVal=GetConVarInt(sm_lc_kick);
	
	switch(kickVal){
		case 1:
		{
			kick = players[clientId][ratio] < 1-GetConVarFloat(sm_lc_kick_ratio);
		}
		case 2:
		{
			kick = players[clientId][warnings] > GetConVarInt(sm_lc_max_warnings);
		}
	}
	
	//still check for min warnings
	if(kick && players[clientId][warnings] > GetConVarInt(sm_lc_min_warnings)){
		//kick
		KickClient(clientId,"%T",TRANSLATION_KICK,clientId);
		debuglogging( 1,"lcKick");
	}
	else if(players[clientId][ratio] < 1-GetConVarFloat(sm_lc_warn_ratio)){
		//warn
		if(kickVal == 2)
		{
			new warnLeft = GetConVarInt(sm_lc_max_warnings) - players[clientId][warnings];
			PrintCenterText(clientId,"%T",TRANSLATION_WARN_COUNT,clientId,warnLeft);
		}
		else{
			PrintCenterText(clientId,"%T",TRANSLATION_WARN,clientId);
		}
		debuglogging(1, "lcWarn");
		players[clientId][warnings]++;
	}
	players[clientId][lastRatio]=players[clientId][ratio];
}

/**
 * 
 * RESET AND STUFF
 * 
 */

public bool:OnClientConnect(client,String:rejectmsg[],maxlen){
	resetPlayer(client);
	return true;
}

resetPlayer(client){
	if(client > 0 && client <=  GetMaxClients() && IsClientInGame(client) && !IsFakeClient(client)){
		players[client][userid] = GetClientUserId(client);
		players[client][ratio] = 1.0;
		players[client][lastRatio] = 1.0;
		players[client][wordcount] = 0;
		players[client][warnings] = 0;
	}
}

RemoveEmptyStrings(String:words[][],lwordcount){
	for(new i=0;i<lwordcount;i++){
		if(strlen(words[i]) == 0){
			for(new j=i+1;j<lwordcount;j++){
				strcopy(words[j-1], MAX_WORD_LENGHT, words[j]);
			}
			lwordcount--;
		}
	}
	return lwordcount;
}

debuglogging(loglevel,const String:format[],any:...){
	if(loglevel <= GetConVarInt(sm_lc_logging)){
		decl String:buffer[1024];
		VFormat(buffer,sizeof(buffer),format,3);
		LogMessage( buffer );
	}
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL)
    }
}

public Updater_OnPluginUpdated(){
	ReloadPlugin();
}
