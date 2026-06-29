/**
 * timedadmin.sp
 * Give certain users admin at certain times of the day.
 */  

#pragma semicolon 1

#include <sourcemod>

new AdminFlag:g_FlagLetters[26];
new bool:g_FlagsSet[26];
new g_IgnoreLevel = 0;
new bool:g_LoggedFileName = false;
new String:g_Filename[PLATFORM_MAX_PATH];
new g_ErrorCount;

ParseError(const String:format[], {Handle,String,Float,_}:...)
{
	decl String:buffer[512];
	
	if (!g_LoggedFileName)
	{
		LogError("Error(s) detected parsing %s", g_Filename);
		g_LoggedFileName = true;
	}
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	LogError(" (%d) %s", ++g_ErrorCount, buffer);
}

#include "admin-flatfile\admin-levels.sp"

new Handle:cvarUpdateTime;
new Float:cachedUpdateTime;

public Plugin:myinfo = 
{
    name = "Timed Admin",
    author = "PimpinJuice",
    description = "Give certain users admin at certain times of the day.",
    version = "0.1",
    url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
    // create admin flag cache
    LoadDefaultLetters();
	
    // init cvars and cached values
    cvarUpdateTime = CreateConVar("sm_ta_updatetime","1.0","How often to check the time for admin changes, in minutes. For performance reasons, it is recommended to stay <=1 minute.");
    HookConVarChange(cvarUpdateTime,RecacheUpdateTime);
    cachedUpdateTime = GetConVarFloat(cvarUpdateTime) * 60.0;
    
    // start the check timer
    CreateTimer(cachedUpdateTime,AdminTimeCheck);
}

public RecacheUpdateTime(Handle:cvar, const String:oldVal[], const String:newVal[])
{
    if(cvar==cvarUpdateTime)
        cachedUpdateTime = GetConVarFloat(cvarUpdateTime) * 60.0;
}

StringToDay(String:str[16])
{
    if(StrEqual(str,"Sunday",false))
        strcopy(str,sizeof(str),"sun");
    else if(StrEqual(str,"Monday",false))
        strcopy(str,sizeof(str),"mon");
    else if(StrEqual(str,"Tuesday",false))
        strcopy(str,sizeof(str),"tues");
    else if(StrEqual(str,"Wednesday",false))
        strcopy(str,sizeof(str),"wed");
    else if(StrEqual(str,"Thursday",false))
        strcopy(str,sizeof(str),"thurs");
    else if(StrEqual(str,"Friday",false))
        strcopy(str,sizeof(str),"fri");
    else if(StrEqual(str,"Saturday",false))
        strcopy(str,sizeof(str),"sat");
}

FindNextRuleBreak(const String:str[128],cur_rule_break)
{
    ++cur_rule_break;
    for(new x=cur_rule_break;x<strlen(str);x++)
    {
        if(str[x]==';')
            return x;
    }
    if(strlen(str)==cur_rule_break-1)
        return -1;
    else
        return strlen(str);
}

bool:SliceRuleUp(const String:rule[128],&sh,&sm,&eh,&em)
{
    // find the split of the two times
    new split_pos=-1;
    for(new x=0;x<strlen(rule);x++)
    {
        if(rule[x]=='-')
        {
            split_pos=x;
        }
    }
    if(split_pos<0 || (strlen(rule)-1 == split_pos))
    {
        return false; // there was a formatting error
    }
    new String:hour[8];
    new String:min[8];
    new bool:hour_b=true;
    for(new x=0;x<split_pos;x++)
    {
        if(hour_b && rule[x]==':')
        {
            hour_b=false;
            continue;
        }
        if(hour_b)
        {
            Format(hour,sizeof(hour),"%s%c",hour,rule[x]);
        }
        else
        {
            Format(min,sizeof(min),"%s%c",min,rule[x]);
        }
    }
    sh = StringToInt(hour);
    sm = StringToInt(min);
    
    strcopy(hour,sizeof(hour),"");
    strcopy(min,sizeof(min),"");
    
    // time for part 2
    hour_b=true;
    for(new x=split_pos+1;x<strlen(rule);x++)
    {
        if(hour_b && rule[x]==':')
        {
            hour_b=false;
            continue;
        }
        if(hour_b)
        {
            Format(hour,sizeof(hour),"%s%c",hour,rule[x]);
        }
        else
        {
            Format(min,sizeof(min),"%s%c",min,rule[x]);
        }
    }
    eh = StringToInt(hour);
    em = StringToInt(min);
    
    return true; // we have reached the end and there hasn't been a fail call
}

public OnRebuildAdminCache(AdminCachePart:part)
{
    if(part==AdminCache_Admins)
    {
        // get hour, minute, day
        new hour,min;
        decl String:time_stamp[16];
        decl String:day[16];
        FormatTime(day,sizeof(day),"%A");
        StringToDay(day);
        FormatTime(time_stamp,sizeof(time_stamp),"%H");
        hour = StringToInt(time_stamp);
        FormatTime(time_stamp,sizeof(time_stamp),"%M");
        min = StringToInt(time_stamp);
        new bit_check = (hour<<16) + min;
        // check flag changes
        RefreshLevels();
        // parse admins_timed.cfg
        new Handle:kv = CreateKeyValues("TimedAdmins");
        decl String:path[1024];
        BuildPath(Path_SM,path,sizeof(path),"configs/admins_timed.cfg");
        FileToKeyValues(kv,path);
        if (KvGotoFirstSubKey(kv))
        {
            decl String:unique_id[255];
            do
            {
                KvGetSectionName(kv,unique_id,sizeof(unique_id));
                decl String:auth_type[64];
                KvGetString(kv,"auth",auth_type,sizeof(auth_type));
                decl String:auth_identity[64];
                KvGetString(kv,"identity",auth_identity,sizeof(auth_identity));
                new bool:allow_admin=false;
                // they are day permitted, but time?
                decl String:time_rule[128];
                new rule_break=-1;
                new old_rule_break=-1;
                KvGetString(kv,"every_day",time_rule,sizeof(time_rule));
                decl String:time_rule2[128];
                KvGetString(kv,day,time_rule2,sizeof(time_rule2));
                Format(time_rule,sizeof(time_rule),"%s;%s",time_rule,time_rule2);
                if(time_rule[0]==';')
                    strcopy(time_rule,sizeof(time_rule),time_rule[1]);
                ReplaceString(time_rule,sizeof(time_rule)," ","");
                if(time_rule[strlen(time_rule)-1]==';')
                    time_rule[strlen(time_rule)-1]='\0';
                new bool:okay=false;
                for(;;)
                {
                    old_rule_break = rule_break;
                    rule_break = FindNextRuleBreak(time_rule,rule_break);
                    if(rule_break == -1)
                    {
                        if(okay)
                            allow_admin = true;
                        break; // no more rules
                    }
                    new sh,sm,eh,em;
                    decl String:rule[128];
                    strcopy(rule,sizeof(rule),time_rule[old_rule_break+1]);
                    rule[rule_break-old_rule_break-1]='\0';
                    if(SliceRuleUp(rule,sh,sm,eh,em))
                    {
                        new min_bit = (sh<<16) + sm;
                        new max_bit = (eh<<16) + em;
                        if(bit_check>=min_bit && bit_check<=max_bit)
                            okay=true;
                    }
                }
                new AdminId:adm_id = FindAdminByIdentity(auth_type,auth_identity);
                if(adm_id == INVALID_ADMIN_ID)
                {
                    if(!allow_admin)
                        continue;
                    else
                    {
                        adm_id = CreateAdmin(unique_id);
                        BindAdminIdentity(adm_id,auth_type,auth_identity);
                    }
                }
                if(adm_id)
                {
                    if(!allow_admin)
                        RemoveAdmin(adm_id);
                    else
                    {
                        // give them admin rights
                        decl String:group_str[128];
                        KvGetString(kv,"group",group_str,sizeof(group_str));
                        if(group_str[0])
                        {
                            // tie them to an admin group
                            new GroupId:id=FindAdmGroup(group_str);
                            if(id == INVALID_GROUP_ID)
                                LogError("Unknown group \"%s\"", group_str);
                            AdminInheritGroup(adm_id,id);
                        }
                        decl String:password_str[24];
                        KvGetString(kv,"password",password_str,sizeof(password_str));
                        if(password_str[0])
                            SetAdminPassword(adm_id,password_str);
                        decl String:flags_str[128];
                        KvGetString(kv,"flags",flags_str,sizeof(flags_str));
                        if(flags_str[0])
                        {
                            new len = strlen(flags_str);
                            for(new i=0;i<len;i++)
                            {
                                if(flags_str[i]<'a' || flags_str[i]>'z')
                                    LogError("Invalid flag detected: %c", flags_str[i]);
                                new val = flags_str[i] - 'a';
                                if(g_FlagsSet[val])
                                    SetAdminFlag(adm_id,g_FlagLetters[val],true);
                                else
                                    LogError("Flag not set: %c",flags_str[i]);
                            }
                        }
                    }
                }
            } while (KvGotoNextKey(kv));
        }
        CloseHandle(kv);
    }
}

public Action:AdminTimeCheck(Handle:timer)
{
    DumpAdminCache(AdminCache_Groups, true);
    DumpAdminCache(AdminCache_Overrides, true);
    DumpAdminCache(AdminCache_Admins, true);
    CreateTimer(cachedUpdateTime,AdminTimeCheck);
}