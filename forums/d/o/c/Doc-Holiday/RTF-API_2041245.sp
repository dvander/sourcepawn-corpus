/**
 * -----------------------------------------------------
 * File        RTF-API.sp
 * Authors     SavSin
 * License     GPLv3
 * Web         http://www.norcalbots.com
 * -----------------------------------------------------
 * 
 * Report To Forums API
 * Copyright (C) 2013 SavSin
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>
 */

#pragma semicolon 1

#include <sourcemod>
#include <RTF>

#undef REQUIRE_PLUGIN
#include <updater>

new const String:PLUGIN_NAME[] = "Report To Forums API";
new const String:PLUGIN_AUTHOR[] = "SavSin";
new const String:PLUGIN_VERSION[] = "2.0.1dev";
new const String:PLUGIN_DESCRIPTION[] = "Provides an API to submit messages to your forums.";
new const String:PLUGIN_DEVSITE[] = "www.norcalbots.com/";
new const String:UPDATE_URL[] = "http://scripts.norcalbots.com/report-to-forums-api/raw/default/rtfupdate.txt";

enum SupportedForums
{
	FORUM_UNSUPPORTED,
	FORUM_VB4,
	FORUM_MYBB,
	FORUM_SMF,
	FORUM_PHPBB,
	FORUM_WBBLITE,
	FORUM_AEF,
	FORUM_USEBB,
	FORUM_XMB,
	FORUM_IPBOARDS
}

/* Plugin ConVars */
new Handle:g_Cvar_TablePrefix = INVALID_HANDLE;
new Handle:g_Cvar_ForumSoftwareID = INVALID_HANDLE;
new Handle:g_Cvar_VPSTimeDiff = INVALID_HANDLE;
new Handle:g_Cvar_AutoUpdate = INVALID_HANDLE;

/* Forward Handles */
new Handle:g_Forward_OnMessageSend = INVALID_HANDLE;
new Handle:g_Forward_OnMessageSendPost = INVALID_HANDLE;

/* SQL Handles */
new Handle:g_hSQLDatabase = INVALID_HANDLE;

/* Post Info */
new String:g_szPostTitle[1024];
new String:g_szPostMessage[1024];

/* Misc Variables */
new SupportedForums:g_iForumSoftwareID;
new g_iForumID;
new g_iThreadID;
new g_iPostID;
new g_iTargetIndex;
new g_iSenderID;
new String:g_szSenderUserName[MAX_NAME_LENGTH];
new String:g_szSenderEmailAddress[64];
new String:g_szTablePrefix[32];
new g_iTimeStamp;
new g_iSenderIndex;
new bool:g_bError;


public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_DEVSITE
};

public OnPluginStart()
{
	/* RTF API Version */
	CreateConVar("rtf_api_version", PLUGIN_VERSION, "Version of RTF API", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	/* Plugin ConVars */
	g_Cvar_TablePrefix = CreateConVar("rtf_table_prefix", "", "Prefix to the tables in your forums database.");
	g_Cvar_ForumSoftwareID = CreateConVar("rtf_forum_softwareid", "", "Forum Software ID.", _, true, 1.0, true, 9.0);
	g_Cvar_VPSTimeDiff = CreateConVar("rtf_vps_time_diff", "", "Time difference used for VPS servers.");
	g_Cvar_AutoUpdate = CreateConVar("rtf_auto_update", "", "Toggles the auto update script");
	
	HookConVarChange(g_Cvar_AutoUpdate, OnConVarChange);
	
	/* Create Global Forwards */
	g_Forward_OnMessageSend = CreateGlobalForward("RTF_OnMessageSend", ET_Event, Param_Cell, Param_Cell, Param_String, Param_String);
	g_Forward_OnMessageSendPost = CreateGlobalForward("RTF_OnMessageSendPost", ET_Ignore, Param_Cell, Param_Cell, Param_String, Param_Cell, Param_String);
	
	/* Create AutoExecConfig */
	RTF_AutoExecConfig("rtfconfig");
	
	/* Connect to the Database */
	if(!SQL_CheckConfig("rtfsettings"))
		SetFailState("SQL Config not found. Check your databases.cfg");
	else
		SQL_TConnect(MySQL_ConnectionCallback, "rtfsettings");
		
	if(LibraryExists("updater") && GetConVarBool(g_Cvar_AutoUpdate))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnLibraryAdded(const String:szLibrary[])
{
	if(StrEqual(szLibrary, "updater", false) && GetConVarBool(g_Cvar_AutoUpdate))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	/* Make the Library Required */
	RegPluginLibrary("RTF-API");
	
	/* Create Plugin Natives */
	CreateNative("RTF_SendForumMessage", Native_SendForumMessage);
	CreateNative("RTF_SetPosterInfo", Native_SetPosterInfo);
}

public OnConfigsExecuted()
{
	/* Cache the Forum Softare ID */
	g_iForumSoftwareID = SupportedForums:GetConVarInt(g_Cvar_ForumSoftwareID);
	
	/* Get the Table Prefix */
	GetConVarString(g_Cvar_TablePrefix, g_szTablePrefix, sizeof(g_szTablePrefix));
}

public OnConVarChange(Handle:hConVar, const String:szOldValue[], const String:szNewValue[])
{
	if(hConVar == g_Cvar_AutoUpdate)
	{
		if(StringToInt(szNewValue) && LibraryExists("updater"))
		{
			Updater_AddPlugin(UPDATE_URL);
		}
		else
		{
			Updater_RemovePlugin();
		}
	}
}

public MySQL_ConnectionCallback(Handle:hOwner, Handle:hDatabase, const String:szError[], any:data)
{
	if(hDatabase != INVALID_HANDLE)
	{
		g_hSQLDatabase = hDatabase;
		SQL_TQuery(g_hSQLDatabase, MySQL_SetNames, "SET NAMES 'utf8'");
	}
	else
		SetFailState("Failed To Connect: %s", szError);
}

public SendForumPost()
{
	decl String:szSQLQuery[1024], String:szSafeTitle[512], String:szSafeTitleSpace[1024], String:szSafePosterName[MAX_NAME_LENGTH];
	GetWebSafeString(g_szPostTitle, szSafeTitle, sizeof(szSafeTitle), false);
	GetWebSafeString(g_szPostTitle, szSafeTitleSpace, sizeof(szSafeTitleSpace), false);
	GetWebSafeString(g_szSenderUserName, szSafePosterName, sizeof(szSafePosterName), true);
	
	switch(g_iForumSoftwareID)
	{
		case FORUM_VB4:
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sthread (title, lastpost, forumid, open, postusername, postuserid, lastposter, lastposterid, dateline, visible) VALUES ('%s', '%d', '%d', '1', '%s', '%d', '%s', '%d', '%d', '1');", g_szTablePrefix, szSafeTitle, g_iTimeStamp, g_iForumID, g_szSenderUserName, g_iSenderID, g_szSenderUserName, g_iSenderID, g_iTimeStamp);
		case FORUM_MYBB:
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sthreads (fid, subject, uid, username, dateline, firstpost, lastpost, visible) VALUES ('%d', '%s', '%d', '%s', '%d', '1', '%d', '1');", g_szTablePrefix, g_iForumID, szSafeTitle, g_iSenderID, g_szSenderUserName, g_iTimeStamp, g_iTimeStamp);			
		case FORUM_SMF:
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %stopics (id_board, approved) VALUES ('%d', '1');", g_szTablePrefix, g_iForumID);
		case FORUM_PHPBB:
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %stopics (forum_id, topic_approved, topic_title, topic_poster, topic_time, topic_views, topic_first_poster_name, topic_first_poster_colour, topic_last_poster_id, topic_last_poster_name, topic_last_post_subject, topic_last_post_time, topic_last_view_time) VALUES ('%d', '1', '%s', '%d', '%d', '1', '%s', 'AA0000', '%d', '%s', '%s', '%d', '%d');", g_szTablePrefix, g_iForumID, szSafeTitle, g_iSenderID, g_iTimeStamp, g_szSenderUserName, g_iSenderID, g_szSenderUserName, szSafeTitle, g_iTimeStamp, g_iTimeStamp);
		case FORUM_WBBLITE:
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sthread (boardID, topic, time, userID, username, lastPostTime, lastPosterID, lastPoster) VALUES ('%d', '%s', '%d', '%d', '%s', '%d', '%d', '%s');", g_szTablePrefix, g_iForumID, szSafeTitle, g_iTimeStamp, g_iSenderID, g_szSenderUserName, g_iTimeStamp, g_iSenderID, g_szSenderUserName);
		case FORUM_AEF:
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %stopics (topic, t_bid, t_status, t_mem_id, t_approved) VALUES ('%s', '%d', '1', '%d', '1');", g_szTablePrefix, szSafeTitle, g_iForumID, g_iSenderID);
		case FORUM_USEBB:
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %stopics (forum_id, topic_title) VALUES ('%d', '%s');", g_szTablePrefix, g_iForumID, szSafeTitle);
		case FORUM_XMB:
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sthreads (fid, subject, author) VALUES ('%d', '%s', '%s');", g_szTablePrefix, g_iForumID, szSafeTitle, g_szSenderUserName);
		case FORUM_IPBOARDS:
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %stopics (title, state, posts, starter_id, start_date, last_poster_id, last_post, starter_name, last_poster_name, poll_state, last_vote, views, forum_id, approved, author_mode, pinned, title_seo, seo_first_name, seo_last_name, last_real_post) VALUES ('%s', 'open', '1', '%d', '%d', '%d', '%d', '%s', '%s', '0', '0', '1', '%d', '1', '1', '0', '%s', '%s', '%s', '%d');", g_szTablePrefix, szSafeTitleSpace, g_iSenderID, g_iTimeStamp, g_iSenderID, g_iTimeStamp, g_szSenderUserName, g_szSenderUserName, g_iForumID, szSafeTitle, szSafePosterName, szSafePosterName, g_iTimeStamp);
	}
	
	SQL_TQuery(g_hSQLDatabase, MySQL_InsertThread, szSQLQuery);
}

/* Finds the Thread ID for the thread we just created */
public FindRecentThread()
{
	decl String:szSQLQuery[512];
	switch(g_iForumSoftwareID)
	{
		case FORUM_VB4:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT threadid FROM %sthread WHERE dateline='%d';", g_szTablePrefix, g_iTimeStamp);
		case FORUM_MYBB:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT tid FROM %sthreads WHERE dateline='%d';", g_szTablePrefix, g_iTimeStamp);
		case FORUM_SMF:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT MAX(id_topic) FROM %stopics;", g_szTablePrefix);
		case FORUM_PHPBB:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT topic_id FROM %stopics WHERE topic_time='%d';", g_szTablePrefix, g_iTimeStamp);
		case FORUM_WBBLITE:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT threadID FROM %sthread WHERE time='%d';", g_szTablePrefix, g_iTimeStamp);
		case FORUM_AEF:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT MAX(tid) FROM %stopics;", g_szTablePrefix);
		case FORUM_USEBB:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT MAX(id) FROM %stopics;", g_szTablePrefix);
		case FORUM_XMB:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT tid FROM %stopics WHERE lastpost='%d';", g_szTablePrefix, g_iTimeStamp);
		case FORUM_IPBOARDS:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT tid FROM %stopics WHERE last_post='%d';", g_szTablePrefix, g_iTimeStamp);
	}
	
	SQL_TQuery(g_hSQLDatabase, MySQL_SelectTid, szSQLQuery);
}

/* Creates the Post (message) for the thread we created */
public CreateThreadPost()
{	
	decl String:szSQLQuery[1024];
	switch(g_iForumSoftwareID)
	{
		case FORUM_VB4:
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %spost (threadid, username, userid, title, dateline, pagetext, allowsmilie, visible, htmlstate) VALUES ('%d', '%s', '%d', '%s', '%d', '%s', '1', '1', 'on_nl2br');", g_szTablePrefix, g_iThreadID, g_szSenderUserName, g_iSenderID, g_szPostTitle, g_iTimeStamp, g_szPostMessage);			
		case FORUM_MYBB:
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sposts (tid, fid, subject, uid, username, dateline, message, visible) VALUES ('%d', '%d', '%s', '%d', '%s', '%d', '%s', '1');", g_szTablePrefix, g_iThreadID, g_iForumID, g_szPostTitle, g_iSenderID, g_szSenderUserName, g_iTimeStamp, g_szPostMessage);			
		case FORUM_SMF:
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %smessages (id_topic, id_board, poster_time, id_member, subject, poster_name, poster_email, body, approved) VALUES ('%d', '%d', '%d', '%d', '%s', '%s', '%s', '%s', '1');", g_szTablePrefix, g_iThreadID, g_iForumID, g_iTimeStamp, g_iSenderID, g_szPostTitle, g_szSenderUserName, g_szSenderEmailAddress, g_szPostMessage);			
		case FORUM_PHPBB:
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sposts (topic_id, forum_id, poster_id, post_time, post_approved, enable_bbcode, post_subject, post_text, post_postcount) VALUES ('%d', '%d', '%d', '%d', '1', '1', '%s', '%s', '1');", g_szTablePrefix, g_iThreadID, g_iForumID, g_iSenderID, g_szSenderUserName, g_iTimeStamp, g_szPostTitle, g_szPostMessage);
		case FORUM_WBBLITE:
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %spost (threadID, userID, username, message, time, enableSmilies, enableBBCodes) VALUES ('%d', '%d', '%s', '%s', '%d', '0', '1');", g_szTablePrefix, g_iThreadID, g_iSenderID, g_szSenderUserName, g_szPostMessage, g_iTimeStamp);
		case FORUM_AEF:
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sposts (post_tid, post_fid, ptime, poster_id, post, use_smileys, p_approved) VALUES ('%d', '%d', '%d', '%d', '%s', '0', '1');", g_szTablePrefix, g_iThreadID, g_iForumID, g_iTimeStamp, g_iSenderID, g_szPostMessage);
		case FORUM_USEBB:
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sposts (topic_id, poster_id, content, post_time, enable_smilies) VALUES ('%d', '%d', '%s', '%d', '0');", g_szTablePrefix, g_iThreadID, g_iSenderID, g_szPostMessage, g_iTimeStamp);
		case FORUM_XMB:
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sposts (fid, tid, author, message, subject, dateline, useip, bbcodeoff, smileyoff) VALUES ('%d', '%d', '%s', '%s', '%s', '%d', '%s', 'no', 'yes');", g_szTablePrefix, g_iForumID, g_iThreadID, g_szSenderUserName, g_szPostMessage, g_szPostTitle, g_iTimeStamp);
		case FORUM_IPBOARDS:
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sposts (author_id, author_name, post_date, post, topic_id, new_topic) VALUES ('%d', '%s', '%d', '%s', '%d', '1');", g_szTablePrefix, g_iSenderID, g_szSenderUserName, g_iTimeStamp, g_szPostMessage, g_iThreadID);
	}
	
	SQL_TQuery(g_hSQLDatabase, MySQL_InsertPostContent, szSQLQuery);
}

/* Finds the Post ID for the thread we just created */
public GetPostId()
{
	decl String:szSQLQuery[512];
	switch(g_iForumSoftwareID)
	{
		case FORUM_VB4:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT postid FROM %spost WHERE dateline='%d';", g_szTablePrefix, g_iTimeStamp);
		case FORUM_SMF:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT id_msg FROM %smessages WHERE poster_time='%d';", g_szTablePrefix, g_iTimeStamp);
		case FORUM_PHPBB:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT post_id FROM %sposts WHERE post_time='%d';", g_szTablePrefix, g_iTimeStamp);
		case FORUM_WBBLITE:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT postID FROM %spost WHERE time='%d';", g_szTablePrefix, g_iTimeStamp);
		case FORUM_AEF:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT pid FROM %sposts WHERE ptime='%d';", g_szTablePrefix, g_iTimeStamp);
		case FORUM_USEBB:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT id FROM %sposts WHERE post_time='%d';", g_szTablePrefix, g_iTimeStamp);
		case FORUM_XMB:
			Format(szSQLQuery, sizeof(szSQLQuery), "SLECT pid FROM %sposts WHERE dateline='%d';", g_szTablePrefix, g_iTimeStamp);
		case FORUM_IPBOARDS:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT pid FROM %sposts WHERE post_date='%d';", g_szTablePrefix, g_iTimeStamp);
	}
	
	SQL_TQuery(g_hSQLDatabase, MySQL_SelectPid, szSQLQuery);
}

/* Sets the Post ID for the thread we just created */
public SetPostId()
{
	decl String:szSQLQuery[512];
	switch(g_iForumSoftwareID)
	{
		case FORUM_VB4:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %sthread SET firstpostid=%d, lastpostid=%d WHERE threadid=%d;", g_szTablePrefix, g_iPostID, g_iPostID, g_iThreadID);
		case FORUM_SMF:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %stopics SET id_first_msg=%d, id_last_msg=%d WHERE id_topic=%d;", g_szTablePrefix, g_iPostID, g_iPostID, g_iThreadID);
		case FORUM_PHPBB:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %stopics SET topic_first_post_id=%d, topic_last_post_id=%d WHERE topic_id=%d;", g_szTablePrefix, g_iPostID, g_iPostID, g_iThreadID);
		case FORUM_WBBLITE:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %sthread SET firstPostID=%d WHERE threadID=%d;", g_szTablePrefix, g_iPostID, g_iThreadID);
		case FORUM_AEF:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %stopics SET first_post_id=%d, last_post_id=%d, mem_id_last_post=%d WHERE tid=%d;", g_szTablePrefix, g_iPostID, g_iPostID, g_iSenderID, g_iThreadID);
		case FORUM_USEBB:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %stopics SET first_post_id=%d, last_post_id=%d WHERE id=%d;", g_szTablePrefix, g_iPostID, g_iPostID, g_iThreadID);
		case FORUM_XMB:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %sthreads SET lastpost='%d|%s|%d' WHERE tid=%d;", g_szTablePrefix, g_iTimeStamp, g_szSenderUserName, g_iPostID, g_iThreadID);
		case FORUM_IPBOARDS:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %stopics SET topic_firstpost='%d' WHERE last_post='%d';", g_szTablePrefix, g_iPostID, g_iTimeStamp);
	}
	
	SQL_TQuery(g_hSQLDatabase, MySQL_UpdatetPid, szSQLQuery);
}

/* Gets the Current Post and Thread count for the specified thread */
public GetCurrentForumPostData()
{
	decl String:szSQLQuery[512];
	switch(g_iForumSoftwareID)
	{
		case FORUM_VB4:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT replycount, threadcount FROM %sforum WHERE forumid='%d';", g_szTablePrefix, g_iForumID);
		case FORUM_MYBB:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT posts, threads FROM %sforums WHERE fid='%d';", g_szTablePrefix, g_iForumID);
		case FORUM_SMF:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT num_posts, num_topics FROM %sboards WHERE id_board='%d';", g_szTablePrefix, g_iForumID);
		case FORUM_PHPBB:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT forum_posts, forum_topics FROM %sforums WHERE forum_id='%d';", g_szTablePrefix, g_iForumID);
		case FORUM_WBBLITE:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT posts, threads FROM %sboard WHERE boardID='%d';", g_szTablePrefix, g_iForumID);
		case FORUM_AEF:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT nposts, ntopic FROM %sforums WHERE fid='%d';", g_szTablePrefix, g_iForumID);
		case FORUM_USEBB:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT posts, topics FROM %sforums WHERE id='%d';", g_szTablePrefix, g_iForumID);
		case FORUM_XMB:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT posts, threads FROM %sforums WHERE fid='%d';", g_szTablePrefix, g_iForumID);
		case FORUM_IPBOARDS:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT posts, topics FROM %sforums WHERE id='%d';", g_szTablePrefix, g_iForumID);
	}
	
	SQL_TQuery(g_hSQLDatabase, MySQL_SelectForumThreadInfo, szSQLQuery);
}

/* Increase the Thread and Post count accordingly */
public UpdateForumPostCount(iPostCount, iThreadCount)
{
	decl String:szSQLQuery[1024];
	
	switch(g_iForumSoftwareID)
	{
		case FORUM_VB4:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %sforum SET threadcount='%d', replycount='%d', lastpost='%d', lastposter='%s', lastposterid='%d', lastpostid='%d', lastthread='%s', lastthreadid='%d' WHERE forumid='%d';", g_szTablePrefix, iThreadCount, iPostCount, g_iTimeStamp, g_szSenderUserName, g_iSenderID, g_iPostID, g_szPostTitle, g_iThreadID, g_iForumID);			
		case FORUM_MYBB:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %sforums SET threads='%d', posts='%d', lastpost='%d', lastposter='%s', lastposteruid='%d', lastposttid='%d', lastpostsubject='%s' WHERE fid='%d';", g_szTablePrefix, iThreadCount, iPostCount, g_iTimeStamp, g_szSenderUserName, g_iSenderID, g_iThreadID, g_szPostTitle, g_iForumID);			
		case FORUM_SMF:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %sboards SET num_topics='%d', num_posts='%d', id_last_msg='%d', id_msg_updated='%d' WHERE id_board='%d';", g_szTablePrefix, iThreadCount, iPostCount, g_iPostID, g_iPostID, g_iForumID);			
		case FORUM_PHPBB:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %sforums SET forum_topics='%d', forum_topics_real='%d', forum_posts='%d', forum_last_post_id='%d', forum_last_post_subject='%s', forum_last_post_time='%d', forum_last_poster_name='%s' WHERE forum_id='%d';", g_szTablePrefix, iThreadCount, iThreadCount, iPostCount, g_iPostID, g_szPostTitle, g_iTimeStamp, g_szSenderUserName, g_iForumID);			
		case FORUM_WBBLITE:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %sboard SET threads='%d', posts='%d' WHERE boardID='%d';", g_szTablePrefix, iThreadCount, iPostCount, g_iForumID);
		case FORUM_AEF:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %sforums SET ntopic='%d', nposts='%d', f_last_pid='%d' WHERE fid ='%d';", g_szTablePrefix, iThreadCount, iPostCount, g_iPostID, g_iForumID);
		case FORUM_USEBB:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %sforums SET topics='%d', posts='%d', last_topic_id='%d' WHERE id='%d';", g_szTablePrefix, iThreadCount, iPostCount, g_iThreadID, g_iForumID);
		case FORUM_XMB:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %sforums SET lastpost='%d', posts='%d', threads='%d' WHERE fid='%d';", g_szTablePrefix, g_iTimeStamp, iPostCount, iThreadCount, g_iForumID);
		case FORUM_IPBOARDS:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %sforums SET topics='%d', posts='%d', last_post='%d', last_poster_id='%d', last_poster_name='%s', last_title='%s', last_id='%d', newest_title='%s', newest_id='%d' WHERE id='%d';", g_szTablePrefix, iThreadCount, iPostCount, g_iTimeStamp, g_iSenderID, g_szSenderUserName, g_szPostTitle, g_iPostID, g_szPostTitle, g_iPostID, g_iForumID);
	}
	
	SQL_TQuery(g_hSQLDatabase, MySQL_UpdateForumPostCount, szSQLQuery);
}

/* Get the Users post count */
public GetUserPostInfo()
{
	decl String:szSQLQuery[512];
	switch(g_iForumSoftwareID)
	{
		case FORUM_VB4:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT posts FROM %suser WHERE userid='%d';", g_szTablePrefix, g_iSenderID);
		case FORUM_MYBB:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT postnum FROM %susers WHERE uid='%d';", g_szTablePrefix, g_iSenderID);
		case FORUM_SMF:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT posts FROM %smembers WHERE id_member='%d';", g_szTablePrefix, g_iSenderID);
		case FORUM_PHPBB:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT user_posts FROM %susers WHERE user_id='%d';", g_szTablePrefix, g_iSenderID);
		case FORUM_WBBLITE:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT posts FROM %suser WHERE userID='%d';", g_szTablePrefix, g_iSenderID);
		case FORUM_AEF:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT posts FROM %susers WHERE id='%d';", g_szTablePrefix, g_iSenderID);
		case FORUM_USEBB:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT posts FROM %smembers WHERE id='%d';", g_szTablePrefix, g_iSenderID);
		case FORUM_XMB:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT postnum FROM %smembers WHERE uid='%d';", g_szTablePrefix, g_iSenderID);
		case FORUM_IPBOARDS:
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT posts FROM %smembers WHERE member_id='%d';", g_szTablePrefix, g_iSenderID);
	}
	
	SQL_TQuery(g_hSQLDatabase, MySQL_GetUserPostCount, szSQLQuery);
}

/* Increase the users post count accordingly */
public UpdateUserPostCount(iPostCount)
{
	decl String:szSQLQuery[512];
	
	switch(g_iForumSoftwareID)
	{
		case FORUM_VB4:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %suser SET posts='%d', lastvisit='%d', lastactivity='%d', lastpost='%d', lastpostid='%d' WHERE userid=%d;", g_szTablePrefix, iPostCount, g_iTimeStamp, g_iTimeStamp, g_iTimeStamp, g_iPostID, g_iSenderID);
		case FORUM_MYBB:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %susers SET postnum='%d' WHERE uid='%d';", g_szTablePrefix, iPostCount, g_iSenderID);
		case FORUM_SMF:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %smembers SET posts='%d', last_login='%d' WHERE id_member=%d;", g_szTablePrefix, iPostCount, g_iTimeStamp, g_iSenderID);
		case FORUM_PHPBB:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %susers SET user_posts='%d', user_lastpost_time='%d' WHERE user_id=%d;", g_szTablePrefix, iPostCount, g_iTimeStamp, g_iSenderID);			
		case FORUM_WBBLITE:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %suser SET posts='%d', boardLastVisitTime='%d', boardLastActivityTime='%d' WHERE userID=%d;", g_szTablePrefix, iPostCount, g_iTimeStamp, g_iTimeStamp, g_iSenderID);
		case FORUM_AEF:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %susers SET lastlogin='%d', lastlogin_1='%d', posts='%d' WHERE id=%d;", g_szTablePrefix, g_iTimeStamp, g_iTimeStamp, iPostCount, g_iSenderID);
		case FORUM_USEBB:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %smembers SET last_login='%d', last_pageview='%d', posts='%d' WHERE id=%d;", g_szTablePrefix, g_iTimeStamp, g_iTimeStamp, iPostCount, g_iSenderID);
		case FORUM_XMB:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %smembers SET postnum='%d', lastvisit='%d';", g_szTablePrefix, iPostCount, g_iTimeStamp);
		case FORUM_IPBOARDS:
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %smembers SET posts='%d', last_post='%d', last_visit='%d', last_activity='%d' WHERE member_id=%d;", g_szTablePrefix, iPostCount, g_iTimeStamp, g_iTimeStamp, g_iTimeStamp, g_iSenderID);
	}
	
	SQL_TQuery(g_hSQLDatabase, MySQL_UpdateUserPostCount, szSQLQuery);
}

public MySQL_SetNames(Handle:hOwner, Handle:hDatabase, const String:szError[], any:data)
{
	if(hDatabase == INVALID_HANDLE)
		LogError("SetNames Error: %s", szError);
}

public MySQL_InsertThread(Handle:hOwner, Handle:hDatabase, const String:szError[], any:data)
{
	if(hDatabase == INVALID_HANDLE)
	{
		decl String:szErrorCode[128];
		Format(szErrorCode, sizeof(szErrorCode), "Failed To Create Thread: %s", szError);
		g_bError = true;
		
		Call_StartForward(g_Forward_OnMessageSendPost);
		Call_PushCell(g_iSenderIndex);
		Call_PushCell(g_iTargetIndex);
		Call_PushString(g_szPostMessage);
		Call_PushCell(g_bError);
		Call_PushString(szErrorCode);
		Call_Finish();
	}
	else
		FindRecentThread();
}

public MySQL_SelectTid(Handle:hOwner, Handle:hDatabase, const String:szError[], any:data)
{
	if(hDatabase == INVALID_HANDLE)
	{
		decl String:szErrorCode[128];
		Format(szErrorCode, sizeof(szErrorCode), "Failed To Select tid: %s", szError);
		g_bError = true;
		
		Call_StartForward(g_Forward_OnMessageSendPost);
		Call_PushCell(g_iSenderIndex);
		Call_PushCell(g_iTargetIndex);
		Call_PushString(g_szPostMessage);
		Call_PushCell(g_bError);
		Call_PushString(szErrorCode);
		Call_Finish();
	}
	else
	{
		if(SQL_GetRowCount(hDatabase))
		{
			SQL_FetchRow(hDatabase);
			g_iThreadID = SQL_FetchInt(hDatabase, 0);
			CreateThreadPost();
		}
	}
}

public MySQL_InsertPostContent(Handle:hOwner, Handle:hDatabase, const String:szError[], any:data)
{
	if(hDatabase == INVALID_HANDLE)
	{
		decl String:szErrorCode[128];
		Format(szErrorCode, sizeof(szErrorCode), "Failed insert post message: %s", szError);
		g_bError = true;
		
		Call_StartForward(g_Forward_OnMessageSendPost);
		Call_PushCell(g_iSenderIndex);
		Call_PushCell(g_iTargetIndex);
		Call_PushString(g_szPostMessage);
		Call_PushCell(g_bError);
		Call_PushString(szErrorCode);
		Call_Finish();
	}
	else
	{
		if(g_iForumSoftwareID != FORUM_MYBB)
			GetPostId();
		else
			GetCurrentForumPostData();
	}
}

public MySQL_SelectPid(Handle:hOwner, Handle:hDatabase, const String:szError[], any:data)
{
	if(hDatabase == INVALID_HANDLE)
	{
		decl String:szErrorCode[128];
		Format(szErrorCode, sizeof(szErrorCode), "Failed To Select post id: %s", szError);
		g_bError = true;
		
		Call_StartForward(g_Forward_OnMessageSendPost);
		Call_PushCell(g_iSenderIndex);
		Call_PushCell(g_iTargetIndex);
		Call_PushString(g_szPostMessage);
		Call_PushCell(g_bError);
		Call_PushString(szErrorCode);
		Call_Finish();
	}
	else
	{
		if(SQL_GetRowCount(hDatabase))
		{
			SQL_FetchRow(hDatabase);
			g_iPostID = SQL_FetchInt(hDatabase, 0);
			SetPostId();
		}
	}
}

public MySQL_UpdatetPid(Handle:hOwner, Handle:hDatabase, const String:szError[], any:data)
{
	if(hDatabase == INVALID_HANDLE)
	{
		decl String:szErrorCode[128];
		Format(szErrorCode, sizeof(szErrorCode), "Failed To update thread with post id: %s", szError);
		g_bError = true;
		
		Call_StartForward(g_Forward_OnMessageSendPost);
		Call_PushCell(g_iSenderIndex);
		Call_PushCell(g_iTargetIndex);
		Call_PushString(g_szPostMessage);
		Call_PushCell(g_bError);
		Call_PushString(szErrorCode);
		Call_Finish();
	}
	else
		GetCurrentForumPostData();
}

public MySQL_SelectForumThreadInfo(Handle:hOwner, Handle:hDatabase, const String:szError[], any:data)
{
	if(hDatabase == INVALID_HANDLE)
	{
		decl String:szErrorCode[128];
		Format(szErrorCode, sizeof(szErrorCode), "Failed To Select post and thread count: %s", szError);
		g_bError = true;
		
		Call_StartForward(g_Forward_OnMessageSendPost);
		Call_PushCell(g_iSenderIndex);
		Call_PushCell(g_iTargetIndex);
		Call_PushString(g_szPostMessage);
		Call_PushCell(g_bError);
		Call_PushString(szErrorCode);
		Call_Finish();
	}
	else
	{
		if(SQL_GetRowCount(hDatabase))
		{
			SQL_FetchRow(hDatabase);
			new iForumPostCount = (SQL_FetchInt(hDatabase, 0) + 1);
			new iForumThreadCount = (SQL_FetchInt(hDatabase, 1) + 1);
			UpdateForumPostCount(iForumPostCount, iForumThreadCount);
		}
	}
}

public MySQL_UpdateForumPostCount(Handle:hOwner, Handle:hDatabase, const String:szError[], any:data)
{
	if(hDatabase == INVALID_HANDLE)
	{
		decl String:szErrorCode[128];
		Format(szErrorCode, sizeof(szErrorCode), "Failed To Update Thread and Post Count: %s", szError);
		g_bError = true;
		
		Call_StartForward(g_Forward_OnMessageSendPost);
		Call_PushCell(g_iSenderIndex);
		Call_PushCell(g_iTargetIndex);
		Call_PushString(g_szPostMessage);
		Call_PushCell(g_bError);
		Call_PushString(szErrorCode);
		Call_Finish();
	}
	else
		GetUserPostInfo();
}

public MySQL_GetUserPostCount(Handle:hOwner, Handle:hDatabase, const String:szError[], any:data)
{
	if(hDatabase == INVALID_HANDLE)
	{
		decl String:szErrorCode[128];
		Format(szErrorCode, sizeof(szErrorCode), "Failed To Select User Post Data: %s", szError);
		g_bError = true;
		
		Call_StartForward(g_Forward_OnMessageSendPost);
		Call_PushCell(g_iSenderIndex);
		Call_PushCell(g_iTargetIndex);
		Call_PushString(g_szPostMessage);
		Call_PushCell(g_bError);
		Call_PushString(szErrorCode);
		Call_Finish();
	}
	else
	{
		if(SQL_GetRowCount(hDatabase))
		{
			SQL_FetchRow(hDatabase);
			new iUserPostCount = (SQL_FetchInt(hDatabase, 0) + 1);
			UpdateUserPostCount(iUserPostCount);
		}
	}
}

public MySQL_UpdateUserPostCount(Handle:hOwner, Handle:hDatabase, const String:szError[], any:data)
{
	decl String:szErrorCode[128];
	if(hDatabase == INVALID_HANDLE)
	{
		Format(szErrorCode, sizeof(szErrorCode), "Failed To Update User Post Data: %s", szError);
		g_bError = true;
	}
	else
	{
		Format(szErrorCode, sizeof(szErrorCode), "", szError);
		g_bError = false;
	}
	Call_StartForward(g_Forward_OnMessageSendPost);
	Call_PushCell(g_iSenderIndex);
	Call_PushCell(g_iTargetIndex);
	Call_PushString(g_szPostMessage);
	Call_PushCell(g_bError);
	Call_PushString(szErrorCode);
	Call_Finish();
}

public Native_SendForumMessage(Handle:hPlugin, iNumParams)
{
	/* Get Plugin Name for Logging */
	decl String:szPluginName[128];
	GetPluginFilename(hPlugin, szPluginName, sizeof(szPluginName));
	ReplaceString(szPluginName, sizeof(szPluginName), ".smx", "");
	LogMessage("Message Generated by %s.", szPluginName);
	
	/* Get Message Time */
	g_iTimeStamp = (GetTime() - GetConVarInt(g_Cvar_VPSTimeDiff));
	
	/* Get Sender Info */
	g_iSenderIndex = GetNativeCell(1);
	
	/* Get Target Index */
	g_iTargetIndex = GetNativeCell(2);
	
	/* Get Message Info */
	decl String:szMessage[512];
	GetNativeString(3, szMessage, sizeof(szMessage));
	
	/* Get Message Title */
	decl String:szTitle[512];
	GetNativeString(4, szTitle, sizeof(szTitle));
	
	/* Get Message Ready to Send */
	ParseString(g_hSQLDatabase, szMessage, g_szPostMessage, sizeof(g_szPostMessage));
	ParseString(g_hSQLDatabase, szTitle, g_szPostTitle, sizeof(g_szPostTitle));
	
	/* Call the Forward */
	new Action:result;
	Call_StartForward(g_Forward_OnMessageSend);
	Call_PushCell(g_iSenderIndex);
	Call_PushCell(g_iTargetIndex);
	Call_PushString(szMessage);
	Call_PushString(szTitle);
	Call_Finish(result);
	
	if(result == Plugin_Continue)
	{
		/* Send the Message to Forums */
		SendForumPost();
	}
}

public Native_SetPosterInfo(Handle:hPlugin, iNumParams)
{
	/* Store Forum Settings */
	g_iForumID = GetNativeCell(1);
	g_iSenderID = GetNativeCell(2);
	GetNativeString(3, g_szSenderUserName, sizeof(g_szSenderUserName));
	GetNativeString(4, g_szSenderEmailAddress, sizeof(g_szSenderEmailAddress));
}

stock ParseString(Handle:hDB, const String:szString[], String:szBuffer[], len)
{
	SQL_EscapeString(hDB, szString, szBuffer, len);
	ReplaceString(szBuffer, len, "}", "");
	ReplaceString(szBuffer, len, "{", "");
	ReplaceString(szBuffer, len, "|", "");
}

/* Written By Impact */
stock LongToIp(long, String:str[], maxlen)
{
	new pieces[4];
	
	pieces[0] = (long >>> 24 & 255);
	pieces[1] = (long >>> 16 & 255);
	pieces[2] = (long >>> 8 & 255);
	pieces[3] = (long & 255); 
	
	Format(str, maxlen, "%d.%d.%d.%d", pieces[0], pieces[1], pieces[2], pieces[3]); 
}