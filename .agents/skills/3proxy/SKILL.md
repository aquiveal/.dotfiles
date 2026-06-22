---
name: 3proxy
description: Provides specialized context, rules, and tools for implementing, configuring, and debugging 3proxy. Use this skill whenever modifying 3proxy configurations or adding related functionality.
---
# 3proxy

## File Tree

```text
3proxy/
├── assets
├── modules
│   └── 3proxy (See AST Map below)
├── references
├── scripts
└── SKILL.md
```

### AST Map: `modules/3proxy`

```python
src\acl.c:
⋮
│int ACLmatches(struct ace* acentry, struct clientparam * param){
│	struct userlist * userentry;
│	struct iplist *ipentry;
│	struct portlist *portentry;
│	struct period *periodentry;
│	unsigned char * username;
│	struct hostname * hstentry=NULL;
│	int i;
│	int match = 0;
│
⋮
│int checkACL(struct clientparam * param){
│	struct ace* acentry;
│
│	if(!param->srv->acl) {
│		return 0;
│	}
│	for(acentry = param->srv->acl; acentry; acentry = acentry->next) {
│		if(ACLmatches(acentry, param)) {
│			param->nolog = acentry->nolog;
│			param->weight = acentry->weight;
⋮

src\common.c:
⋮
│int myinet_ntop(int af, void *src, char *dst, socklen_t size){
⋮

src\libs\blake2-impl.h:
⋮
│#ifndef BLAKE2_IMPL_H
⋮
│static BLAKE2_INLINE void secure_zero_memory(void *v, size_t n)
⋮

src\plugins.c:
⋮
│int checkACL(struct clientparam * param);
⋮

src\plugins\FilePlugin\FilePlugin.h:
⋮
│extern "C" {
│#endif
│
│
│#define FP_OK 0
│#define FP_REJECT 65536
│
│#define FP_CLIDATA 1
│#define FP_SRVDATA 2
│#define FP_CLIHEADER 4
⋮
│struct fp_filedata {
│ struct clientparam *cp;
│#ifdef _WIN32
│ HANDLE h_cli, h_srv;
│#else
│ int fd_cli, fd_srv;
│#endif
│ char *path_cli;
│ char *path_srv;
⋮

src\proxy.h:
⋮
│#ifndef _3PROXY_H_
⋮
│#ifndef NOSQL
│void logsql(struct clientparam * param, const unsigned char *s);
│int init_sql(char * s);
│void close_sql();
⋮
│int myinet_ntop(int af, void *src, char *dst, socklen_t size);
⋮
│int socks5_udp_build_hdr(unsigned char *buf, PROXYSOCKADDRTYPE *addr);
│
⋮
│int ACLmatches(struct ace* acentry, struct clientparam * param);
│int checkACL(struct clientparam * param);
⋮

src\sql.c:
⋮
│#ifdef WITH_ODBC
│
⋮
│void close_sql(){
│    if(hstmt) {
│	SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
│	hstmt = NULL;
│    }
│    if(hdbc){
│	SQLDisconnect(hdbc);
│	SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
│	hdbc = NULL;
│    }
⋮

src\structures.h:
⋮
│#ifndef _STRUCTURES_H_
⋮
│#ifdef WITH_POLL
│#include <poll.h>
│#else
⋮
│typedef enum {
│	PASS = 0,
│	CONTINUE,
│	HANDLED,
│	REJECT,
│	REMOVE
│} FILTER_ACTION;
│
⋮
│struct clientparam {
│	struct clientparam	*next,
│				*prev;
│	void * sostate;
│	struct srvparam *srv;
│	REDIRECTFUNC redirectfunc;
│	BANDLIMFUNC bandlimfunc;
│	TRAFCOUNTFUNC trafcountfunc;
│
│
⋮

src\udppm.c:
⋮
│int socks5_udp_build_hdr(unsigned char *buf, PROXYSOCKADDRTYPE *addr);
│
⋮

src\udpsockmap.c:
⋮
│int socks5_udp_build_hdr(unsigned char *buf, PROXYSOCKADDRTYPE *addr)
⋮
```
