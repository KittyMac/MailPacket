#include "stdio.h"
#include "stdlib.h"
#include <string.h>
#include <stdint.h>

#include "mailimap.h"

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

int cmailimap_uid_search(void * session, int dt_day, int dt_month, int dt_year) {
    struct mailimap_search_key * search_key;
    struct mailimap_date * imap_date;
    
    imap_date = mailimap_date_new(dt_day, dt_month, dt_year);

    search_key = mailimap_search_key_new(MAILIMAP_SEARCH_KEY_SINCE,
          NULL, NULL, NULL, NULL, NULL,
          NULL, NULL, imap_date, NULL, NULL,
          NULL, NULL, NULL, NULL, 0,
          NULL, NULL, NULL, NULL, NULL,
          NULL, 0, NULL, NULL, NULL);
    
    clist * search_result;
    
    int result = mailimap_uid_search(session, "utf-8", search_key, &search_result);
    
    mailimap_search_key_free(search_key);
    
    if (result == MAILIMAP_NO_ERROR) {
        int count = clist_count(search_result);
        fprintf(stderr, "%d results found", count);
    }
    
    return result;
}

/*
 struct mailimap_search_key {
   int sk_type;
   union {
     char * sk_bcc;
     struct mailimap_date * sk_before;
     char * sk_body;
     char * sk_cc;
     char * sk_from;
     char * sk_keyword;
     struct mailimap_date * sk_on;
     struct mailimap_date * sk_since;
     char * sk_subject;
     char * sk_text;
     char * sk_to;
     char * sk_unkeyword;
     struct {
       char * sk_header_name;
       char * sk_header_value;
     } sk_header;
     uint32_t sk_larger;
     struct mailimap_search_key * sk_not;
     struct {
       struct mailimap_search_key * sk_or1;
       struct mailimap_search_key * sk_or2;
     } sk_or;
     struct mailimap_date * sk_sentbefore;
     struct mailimap_date * sk_senton;
     struct mailimap_date * sk_sentsince;
     uint32_t sk_smaller;
     struct mailimap_set * sk_uid;
     struct mailimap_set * sk_set;
     uint64_t sk_xgmthrid;
     uint64_t sk_xgmmsgid;
     char * sk_xgmraw;
     clist * sk_multiple; // list of (struct mailimap_search_key *)
     struct {
       struct mailimap_flag * sk_entry_name;
       int sk_entry_type_req;
       uint64_t sk_modseq_valzer;
     } sk_modseq;
   } sk_data;
 };
 */
