#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"
#define PLUGIN_PREFIX "\x04[CTS]\x01"

#define MIN_TAG_LENGTH 3

public Plugin:myinfo = 
{
	name = "Clan Tag Stripper",
	author = "Matheus28",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
}

new String:userName[128][MAX_NAME_LENGTH];
new String:userAuth[128][64];
new userCount;
new userCur;

new String:tags[128][MAX_NAME_LENGTH];
new tagsCount;
new tagsCur;

public OnPluginStart(){
	ResetConVar(CreateConVar("sm_cts_version", PLUGIN_VERSION, "Clan Tag Stripper Version",
	FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY), true, true);
	
	
	HookEvent("player_changename", player_changename);
	
	RegAdminCmd("sm_cts_add", Cmd_AddTag, ADMFLAG_BAN, "Adds a tag for the tag list");
	RegAdminCmd("sm_cts_list", Cmd_List, ADMFLAG_BAN, "Prints the tag list");
	
	for(new i=1;i<=MaxClients;++i){
		if(!IsClientInGame(i)) continue;
		CheckUser(i);
	}
}

public Action:Cmd_AddTag(client, args){
	if(args<1){
		ReplyToCommand(client, "%s Usage: sm_cts_add <tag>", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	decl String:tag[MAX_NAME_LENGTH];
	GetCmdArgString(tag, sizeof(tag));
	
	AddTag(tag);
	CheckAllTags();
	
	ReplyToCommand(client, "%s Tag \x03%s\x01 added", PLUGIN_PREFIX, tag);
	return Plugin_Handled;
}

public Action:Cmd_List(client, args){
	if(tagsCount==0){
		ReplyToCommand(client, "%s No tags", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	if(GetCmdReplySource()==SM_REPLY_TO_CHAT){
		ReplyToCommand(client, "%s Check your console for the tag list", PLUGIN_PREFIX);
		SetCmdReplySource(SM_REPLY_TO_CONSOLE);
	}
	ReplyToCommand(client, "%s Displaying %d tags:", PLUGIN_PREFIX, tagsCount);
	for(new i=0;i<tagsCount;++i){
		ReplyToCommand(client, "- %s", tags[i]);
	}
	return Plugin_Handled;
}

public Action:player_changename(Handle:event,  const String:name[], bool:dontBroadcast) {
	CreateTimer(0.1, Timer_CheckName, GetEventInt(event, "userid"));
	SetEventBroadcast(event, false);
}

public Action:Timer_CheckName(Handle:timer, any:data){
	new client=GetClientOfUserId(data);
	if(client) CheckUser(client);
}

public OnClientPostAdminCheck(client){
	CheckUser(client);
}

public bool:CheckUser(client){
	decl String:name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	
	if(CheckTag(client)) return true;
	
	new id = AddUser(client);
	new c;
	for(new i=0;i<userCount;++i){
		if(i==id) continue;
		c=CompareNames(name, userName[i]);
		if(c>=MIN_TAG_LENGTH){
			decl String:tag[MAX_NAME_LENGTH];
			Select(name, c, tag, sizeof(tag));
			AddTag(tag);
			CheckAllTags();
			return true;
		}
	}
	
	return false;
}

public bool:CheckTag(client){
	decl String:name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	new id=-1;
	new idm=0;
	for(new i=0;i<tagsCount;++i){
		if(HasTag(name, tags[i]) && strlen(tags[i])>idm){
			id=i;
			idm=strlen(tags[i]);
		}
	}
	if(id>-1){
		RemoveTag(client, name, tags[id]);
	}
	return false;
}

public CheckAllTags(){
	decl String:tmp[MAX_NAME_LENGTH];
	for(new j=1;j<=MaxClients;++j){
		if(!IsClientInGame(j)) continue;
		GetClientName(j, tmp, sizeof(tmp));
		for(new t=0;t<tagsCount;++t){
			if(HasTag(tmp, tags[t])){
				RemoveTag(j, tmp, tags[t]);
				break;
			}
		}
	}
}

public RemoveTag(client, const String:name[], const String:tag[]){
	new nameLength=strlen(name);
	new l = strlen(tag);
	decl String:newName[MAX_NAME_LENGTH];
	for(new k=l;k<nameLength;++k){
		newName[k-l]=name[k];
	}
	newName[nameLength-l]='\0';
	TrimString(newName);
	Rename(client, newName);
}

public Rename(client, const String:name[]){
	new l=strlen(name)+1;
	decl String:tmp[l];
	strcopy(tmp, l, name);
	TrimString(tmp);
	if(tmp[0]!='\0'){
		SetClientInfo(client, "name", tmp);
	}
}

public Select(const String:str[], num, String:buffer[], bsize){
	for(new i=0;i<num;++i){
		buffer[i]=str[i];
	}
	buffer[num]='\0';
}

public AddUser(client){
	decl String:auth[sizeof(userAuth[])];
	GetClientAuthString(client, auth, sizeof(auth));
	
	for(new i=0;i<userCount;++i){
		if(StrEqual(auth, userAuth[i])) return i;
	}
	
	GetClientName(client, userName[userCur], sizeof(userName[]));
	strcopy(userAuth[userCur], sizeof(userAuth[]), auth);
	
	new o=userCur;
	
	++userCur;
	if(userCur>=sizeof(userName)) userCur=0;
	if(userCount<userCur) userCount=userCur;
	return o;
}

public AddTag(const String:tag[]){
	for(new i=0;i<tagsCount;++i){
		if(StrEqual(tag, tags[i])) return i;
	}
	
	strcopy(tags[tagsCur], sizeof(tags[]), tag);
	
	new o=userCur;
	
	++tagsCur;
	if(tagsCur>=sizeof(tags)) tagsCur=0;
	if(tagsCount<tagsCur) tagsCount=tagsCur;
	return o;
}

public bool:HasTag(const String:name[], const String:tag[]){
	new max=Min(strlen(name), strlen(tag));
	for(new i=0;i<max;++i){
		if(CharToLower(name[i])!=CharToLower(tag[i])) return false;
	}
	return true;
}

public CompareNames(const String:str1[], const String:str2[]){
	// Any attempt to understand this may result in serious brain damage
	
	new max=Min(strlen(str1), strlen(str2));
	new lbreak;
	new bool:sc=false;
	new ch;
	new bool:ls=false;
	
	for(new i=0;i<max;++i){
		if(CharToLower(str1[i])!=CharToLower(str2[i])) break;
		ch=str1[i];
		if(!IsCharAlpha(ch)
			&& !IsCharNumeric(ch)
			&& ch!='\''
		){
			if(!IsCharSpace(ch)){
				sc=true;
				lbreak=i;
				ls=false;
			}else if(sc){
				sc=false;
				lbreak=i;
				ls=true;
			}
		}
	}
	if(ls&&lbreak){
		return lbreak-1;
	}
	return lbreak;
}

stock Min(n1, n2){
	if(n1>n2) return n2;
	return n1;
}