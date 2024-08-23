#include "stdio.h"
#include "stdlib.h"
#include <string.h>
#include <stdint.h>

#include "mailimap.h"
#include "cJSON.h"

char * cmail_error_string(int result);

void * cmailimap_new() {
    return mailimap_new(0, NULL);
}

void cmailimap_free(void * session) {
    return mailimap_free(session);
}

int cmailimap_logout(void * session) {
    mailimap_logout(session);
}

char * cimap_response(void * session) {
    char * msg = ((mailimap *)session)->imap_response;
    if (msg == NULL) { return msg; }
    return strdup(msg);
}

int cmailimap_ssl_connect(void * f, const char * server, uint16_t port) {
    return mailimap_ssl_connect(f, server, port);
}

int cmailimap_login(void * session, const char * userid, const char * password) {
    return mailimap_login(session, userid, password);
}

int cmailimap_oauth2_authenticate(void * session, const char * userid, const char * password) {
    return mailimap_oauth2_authenticate(session, userid, password);
}

int cmailimap_examine(mailimap * session, const char * mb) {
    return mailimap_examine(session, mb);
}

int cmailimap_select(void * session, const char * mb) {
    return mailimap_select(session, mb);
}

char * cmailimap_list(mailimap * session) {
    clist * search_result;

    int result = mailimap_list(session, "", "*", &search_result);
    if (result >= MAILIMAP_ERROR_BAD_STATE) {
        return strdup(cmail_error_string(result));
    }

    cJSON * cjson = cJSON_CreateArray();
    
    clistiter * cur;
    for(cur = clist_begin(search_result); cur != NULL; cur = clist_next(cur)) {
        struct mailimap_mailbox_list * mailbox = clist_content(cur);
        cJSON_AddItemToArray(cjson, cJSON_CreateString(mailbox->mb_name));
    }
    char * json = cJSON_PrintUnformatted(cjson);
    cJSON_Delete(cjson);

    return json;

}

char * cmailimap_search(void * session,
                        int search_day,
                        int search_month,
                        int search_year,
                        int search_smaller) {
    struct mailimap_search_key * search_key = mailimap_search_key_new_multiple_empty();
    
    if (search_smaller != 0) {
        struct mailimap_search_key * smaller = mailimap_search_key_new_smaller(search_smaller);
        mailimap_search_key_multiple_add(search_key, smaller);
    }
    if (search_year != 0) {
        struct mailimap_date * imap_date = mailimap_date_new(search_day, search_month, search_year);
        struct mailimap_search_key * since = mailimap_search_key_new_since(imap_date);
        mailimap_search_key_multiple_add(search_key, since);
    }

    clist * search_result;
    int result = mailimap_uid_search(session, "utf-8", search_key, &search_result);
    
    mailimap_search_key_free(search_key);
    
    if (result >= MAILIMAP_ERROR_BAD_STATE) {
        return strdup(cmail_error_string(result));
    }
    
    cJSON * cjson = cJSON_CreateArray();

    clistiter * cur;
    for(cur = clist_begin(search_result); cur != NULL; cur = clist_next(cur)) {
        uint32_t * uid = clist_content(cur);
        cJSON_AddItemToArray(cjson, cJSON_CreateNumber(*uid));
    }
    
    char * json = cJSON_PrintUnformatted(cjson);
    cJSON_Delete(cjson);
    
    // mailimap_search_list_free(search_result);

    return json;
}

char * cmailimap_headers(void * session,
                         int num,
                         int * uids) {
    
    struct mailimap_fetch_type * att_list = mailimap_fetch_type_new_fetch_att_list_empty();
        
    struct mailimap_set * uidSet = mailimap_set_new_empty();
    for(int i = 0; i < num; i++) {
        mailimap_set_add_single(uidSet, uids[i]);
    }
        
    mailimap_fetch_type_new_fetch_att_list_add(att_list, mailimap_fetch_att_new_rfc822_header());
    mailimap_fetch_type_new_fetch_att_list_add(att_list, mailimap_fetch_att_new_uid());

    clist * fetch_result;
    int result = mailimap_uid_fetch(session, uidSet, att_list, &fetch_result);
    if (result >= MAILIMAP_ERROR_BAD_STATE) {
        return strdup(cmail_error_string(result));
    }
    
    
    cJSON * cjson = cJSON_CreateArray();

    clistiter * cur;
    for(cur = clist_begin(fetch_result); cur != NULL; cur = clist_next(cur)) {
        struct mailimap_msg_att * msg_att = clist_content(cur);
        
        cJSON * messageJsonObj = cJSON_CreateObject();
        
        clistiter * cur2;
        for(cur2 = clist_begin(msg_att->att_list); cur2 != NULL; cur2 = clist_next(cur2)) {
            struct mailimap_msg_att_item * item = clist_content(cur2);
            
            if (item->att_type != MAILIMAP_MSG_ATT_ITEM_STATIC) {
                continue;
            }
            
            if (item->att_data.att_static->att_type == MAILIMAP_MSG_ATT_UID) {
                cJSON_AddNumberToObject(messageJsonObj, "messageID", item->att_data.att_static->att_data.att_uid);
            }
            
            if (item->att_data.att_static->att_type == MAILIMAP_MSG_ATT_RFC822_HEADER) {
                cJSON_AddStringToObject(messageJsonObj, "headers", item->att_data.att_static->att_data.att_rfc822_header.att_content);
            }
        }
        
        cJSON_AddItemToArray(cjson, messageJsonObj);
    }
    
    char * json = cJSON_PrintUnformatted(cjson);
    cJSON_Delete(cjson);
    
    mailimap_fetch_list_free(fetch_result);

    return json;
}

char * cmailimap_download(void * session,
                          int num,
                          int * uids) {
    
    struct mailimap_fetch_type * att_list = mailimap_fetch_type_new_fetch_att_list_empty();
        
    struct mailimap_set * uidSet = mailimap_set_new_empty();
    for(int i = 0; i < num; i++) {
        mailimap_set_add_single(uidSet, uids[i]);
    }
    
    mailimap_fetch_type_new_fetch_att_list_add(att_list, mailimap_fetch_att_new_rfc822());
    mailimap_fetch_type_new_fetch_att_list_add(att_list, mailimap_fetch_att_new_uid());

    clist * fetch_result;
    int result = mailimap_uid_fetch(session, uidSet, att_list, &fetch_result);
    if (result >= MAILIMAP_ERROR_BAD_STATE) {
        return strdup(cmail_error_string(result));
    }
    
    
    cJSON * cjson = cJSON_CreateArray();

    clistiter * cur;
    for(cur = clist_begin(fetch_result); cur != NULL; cur = clist_next(cur)) {
        struct mailimap_msg_att * msg_att = clist_content(cur);
        
        cJSON * eml = cJSON_CreateObject();

        clistiter * cur2;
        for(cur2 = clist_begin(msg_att->att_list); cur2 != NULL; cur2 = clist_next(cur2)) {
            struct mailimap_msg_att_item * item = clist_content(cur2);
            
            if (item->att_type != MAILIMAP_MSG_ATT_ITEM_STATIC) {
                continue;
            }
            if (item->att_data.att_static->att_type == MAILIMAP_MSG_ATT_UID) {
                cJSON_AddNumberToObject(eml, "messageID", item->att_data.att_static->att_data.att_uid);
            }
            if (item->att_data.att_static->att_type == MAILIMAP_MSG_ATT_RFC822) {
                cJSON_AddStringToObject(eml, "eml", item->att_data.att_static->att_data.att_rfc822.att_content);
            }
        }
        
        cJSON_AddItemToArray(cjson, eml);
    }
    
    char * json = cJSON_PrintUnformatted(cjson);
    cJSON_Delete(cjson);
    
    mailimap_fetch_list_free(fetch_result);

    return json;
}

char * cmail_error_string(int result) {
    switch (result) {
        case MAILIMAP_ERROR_BAD_STATE: return "MAILIMAP_ERROR_BAD_STATE";
        case MAILIMAP_ERROR_STREAM: return "MAILIMAP_ERROR_STREAM";
        case MAILIMAP_ERROR_PARSE: return "MAILIMAP_ERROR_PARSE";
        case MAILIMAP_ERROR_CONNECTION_REFUSED: return "MAILIMAP_ERROR_CONNECTION_REFUSED";
        case MAILIMAP_ERROR_MEMORY: return "MAILIMAP_ERROR_MEMORY";
        case MAILIMAP_ERROR_FATAL: return "MAILIMAP_ERROR_FATAL";
        case MAILIMAP_ERROR_PROTOCOL: return "MAILIMAP_ERROR_PROTOCOL";
        case MAILIMAP_ERROR_DONT_ACCEPT_CONNECTION: return "MAILIMAP_ERROR_DONT_ACCEPT_CONNECTION";
        case MAILIMAP_ERROR_APPEND: return "MAILIMAP_ERROR_APPEND";
        case MAILIMAP_ERROR_NOOP: return "MAILIMAP_ERROR_NOOP";
        case MAILIMAP_ERROR_LOGOUT: return "MAILIMAP_ERROR_LOGOUT";
        case MAILIMAP_ERROR_CAPABILITY: return "MAILIMAP_ERROR_CAPABILITY";
        case MAILIMAP_ERROR_CHECK: return "MAILIMAP_ERROR_CHECK";
        case MAILIMAP_ERROR_CLOSE: return "MAILIMAP_ERROR_CLOSE";
        case MAILIMAP_ERROR_EXPUNGE: return "MAILIMAP_ERROR_EXPUNGE";
        case MAILIMAP_ERROR_COPY: return "MAILIMAP_ERROR_COPY";
        case MAILIMAP_ERROR_UID_COPY: return "MAILIMAP_ERROR_UID_COPY";
        case MAILIMAP_ERROR_MOVE: return "MAILIMAP_ERROR_MOVE";
        case MAILIMAP_ERROR_UID_MOVE: return "MAILIMAP_ERROR_UID_MOVE";
        case MAILIMAP_ERROR_CREATE: return "MAILIMAP_ERROR_CREATE";
        case MAILIMAP_ERROR_DELETE: return "MAILIMAP_ERROR_DELETE";
        case MAILIMAP_ERROR_EXAMINE: return "MAILIMAP_ERROR_EXAMINE";
        case MAILIMAP_ERROR_FETCH: return "MAILIMAP_ERROR_FETCH";
        case MAILIMAP_ERROR_UID_FETCH: return "MAILIMAP_ERROR_UID_FETCH";
        case MAILIMAP_ERROR_LIST: return "MAILIMAP_ERROR_LIST";
        case MAILIMAP_ERROR_LOGIN: return "MAILIMAP_ERROR_LOGIN";
        case MAILIMAP_ERROR_LSUB: return "MAILIMAP_ERROR_LSUB";
        case MAILIMAP_ERROR_RENAME: return "MAILIMAP_ERROR_RENAME";
        case MAILIMAP_ERROR_SEARCH: return "MAILIMAP_ERROR_SEARCH";
        case MAILIMAP_ERROR_UID_SEARCH: return "MAILIMAP_ERROR_UID_SEARCH";
        case MAILIMAP_ERROR_SELECT: return "MAILIMAP_ERROR_SELECT";
        case MAILIMAP_ERROR_STATUS: return "MAILIMAP_ERROR_STATUS";
        case MAILIMAP_ERROR_STORE: return "MAILIMAP_ERROR_STORE";
        case MAILIMAP_ERROR_UID_STORE: return "MAILIMAP_ERROR_UID_STORE";
        case MAILIMAP_ERROR_SUBSCRIBE: return "MAILIMAP_ERROR_SUBSCRIBE";
        case MAILIMAP_ERROR_UNSUBSCRIBE: return "MAILIMAP_ERROR_UNSUBSCRIBE";
        case MAILIMAP_ERROR_STARTTLS: return "MAILIMAP_ERROR_STARTTLS";
        case MAILIMAP_ERROR_INVAL: return "MAILIMAP_ERROR_INVAL";
        case MAILIMAP_ERROR_EXTENSION: return "MAILIMAP_ERROR_EXTENSION";
        case MAILIMAP_ERROR_SASL: return "MAILIMAP_ERROR_SASL";
        case MAILIMAP_ERROR_SSL: return "MAILIMAP_ERROR_SSL";
        case MAILIMAP_ERROR_NEEDS_MORE_DATA: return "MAILIMAP_ERROR_NEEDS_MORE_DATA";
        case MAILIMAP_ERROR_CUSTOM_COMMAND: return "MAILIMAP_ERROR_CUSTOM_COMMAND";
        case MAILIMAP_ERROR_CLIENTID: return "MAILIMAP_ERROR_CLIENTID";
    }
    
    return NULL;
}
