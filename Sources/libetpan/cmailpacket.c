#include "stdio.h"
#include "stdlib.h"
#include <string.h>
#include <stdint.h>

#include "mailimap.h"
#include "cJSON.h"

void * cmailimap_new() {
    return mailimap_new(0, NULL);
}

int cmailimap_ssl_connect(void * f, const char * server, uint16_t port) {
    return mailimap_ssl_connect(f, server, port);
}

int cmailimap_login(void * session, const char * userid, const char * password) {
    return mailimap_login(session, userid, password);
}

int cmailimap_select(void * session, const char * mb) {
    return mailimap_select(session, mb);
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
    int result = mailimap_search(session, "utf-8", search_key, &search_result);
    
    mailimap_search_key_free(search_key);
    
    if (result != MAILIMAP_NO_ERROR) {
        return NULL;
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
    
    // TO FETCH THE ENTIRE MESSAGE
    // mailimap_fetch_att_new_rfc822
    // TO FETCH THE HEADERS ONLY
    // MAILIMAP_FETCH_ATT_RFC822_HEADER
    
    // mailimap_fetch_att_new_rfc822_header();
    
    struct mailimap_set * uidSet = mailimap_set_new_empty();
    for(int i = 0; i < num; i++) {
        mailimap_set_add_single(uidSet, uids[i]);
    }
    
    struct mailimap_fetch_type * fetch_type = mailimap_fetch_type_new_fetch_att(mailimap_fetch_att_new_rfc822_header());

    clist * fetch_result;
    int result = mailimap_fetch(session, uidSet, fetch_type, &fetch_result);
    if (result != MAILIMAP_NO_ERROR) {
        return NULL;
    }
    
    
    cJSON * cjson = cJSON_CreateArray();

    clistiter * cur;
    for(cur = clist_begin(fetch_result); cur != NULL; cur = clist_next(cur)) {
        struct mailimap_msg_att * msg_att = clist_content(cur);
        
        clistiter * cur2;
        for(cur2 = clist_begin(msg_att->att_list); cur2 != NULL; cur2 = clist_next(cur2)) {
            struct mailimap_msg_att_item * item = clist_content(cur2);
            
            if (item->att_type != MAILIMAP_MSG_ATT_ITEM_STATIC) {
                continue;
            }
            if (item->att_data.att_static->att_type != MAILIMAP_MSG_ATT_RFC822_HEADER) {
                continue;
            }

            cJSON * header = cJSON_CreateObject();
            cJSON_AddNumberToObject(header, "messageID", msg_att->att_number);
            cJSON_AddStringToObject(header, "headers", item->att_data.att_static->att_data.att_rfc822_header.att_content);
            cJSON_AddItemToArray(cjson, header);
        }
    }
    
    char * json = cJSON_PrintUnformatted(cjson);
    cJSON_Delete(cjson);
    
    mailimap_fetch_list_free(fetch_result);

    return json;
}
