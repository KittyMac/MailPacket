#ifndef ctess_h
#define ctess_h

#import <stdlib.h>
#include <stdint.h>

typedef struct CIMAP {
    void * mailimap;
} CIMAP;

extern void * cmailimap_new();
extern void * cmailimap_free(void * session);
extern char * cimap_response(void * session);
extern int cmailimap_ssl_connect(void * f, const char * server, uint16_t port);
extern int cmailimap_oauth2_authenticate(void * session, const char * userid, const char * password);
extern int cmailimap_login(void * session, const char * userid, const char * password);
extern int cmailimap_select(void * session, const char * mb);
extern char * cmailimap_list(void * session);
extern char * cmailimap_search(void * session,
                               int search_day,
                               int search_month,
                               int search_year,
                               int search_smaller);
extern char * cmailimap_headers(void * session,
                                int num,
                                int * uids);
extern char * cmailimap_download(void * session,
                                 int num,
                                 int * uids);
#endif
