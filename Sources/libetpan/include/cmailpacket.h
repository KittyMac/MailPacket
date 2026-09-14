#ifndef ctess_h
#define ctess_h

#import <stdlib.h>
#include <stdint.h>
#include <stdbool.h>

typedef struct CIMAP {
    void * mailimap;
} CIMAP;

extern void * cmailimap_new();
extern void * cmailimap_free(void * session);
extern int cmailimap_logout(void * session);
extern char * cimap_response(void * session);
extern int cmailimap_ssl_connect(void * f, const char * server, uint16_t port);
extern int cmailimap_oauth2_authenticate(void * session, const char * userid, const char * password);
extern int cmailimap_login(void * session, const char * userid, const char * password);
extern bool cmailimap_has_extension(void * session, const char * extension_name);
extern int cmailimap_examine(void * session, const char * mb);
extern int cmailimap_select(void * session, const char * mb);
extern char * cmailimap_list(void * session);
extern char * cmailimap_search(void * session,
                               int search_day,
                               int search_month,
                               int search_year,
                               int search_smaller);
extern char * cmailimap_headers(void * session,
                                int num,
                                int * uids,
                                bool hasGmailExtension);
extern char * cmailimap_download(void * session,
                                 int num,
                                 int * uids,
                                 bool hasGmailExtension);
extern int cmailimap_append(void * session,
                            const char * mailbox,
                            const char * eml,
                            int eml_size,
                            bool seen);

extern void * cmailsmtp_new(void);
extern void cmailsmtp_free(void * session);
extern char * csmtp_response(void * session);
extern int cmailsmtp_ssl_connect(void * session, const char * server, uint16_t port);
extern int cmailsmtp_starttls_connect(void * session, const char * server, uint16_t port);
extern int cmailsmtp_login(void * session, const char * userid, const char * password);
extern int cmailsmtp_oauth2_authenticate(void * session, const char * userid, const char * access_token);
extern int cmailsmtp_send(void * session,
                          const char * from,
                          int num_recipients,
                          const char ** recipients,
                          const char * eml,
                          int eml_size);
extern int cmailsmtp_quit(void * session);
#endif
