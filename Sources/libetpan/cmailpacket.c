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

char * cmailimap_uid_search(void * session,
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
    
    if (result != MAILIMAP_NO_ERROR) {
        return NULL;
    }
    
    clistiter * cur;
    cJSON * cjson = cJSON_CreateArray();

    for(cur = clist_begin(search_result); cur != NULL; cur = clist_next(cur)) {
        uint32_t * uid = clist_content(cur);
        cJSON_AddItemToArray(cjson, cJSON_CreateNumber(*uid));
    }
    
    char * json = cJSON_PrintUnformatted(cjson);
    cJSON_Delete(cjson);

    return json;
}
