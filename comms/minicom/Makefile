# Created by: obrien@cs.ucdavis.edu

PORTNAME=	minicom
PORTVERSION=	2.7.1
PORTREVISION=	2
CATEGORIES=	comms
MASTER_SITES=	https://fossies.org/linux/misc/

MAINTAINER=	ports@FreeBSD.org
COMMENT=	MS-DOS Telix serial communication program "workalike"

LICENSE=	GPLv2+
LICENSE_FILE=	${WRKSRC}/COPYING

RUN_DEPENDS=	lrz:comms/lrzsz

USES=		iconv localbase ncurses
GNU_CONFIGURE=	yes
CONFIGURE_ARGS=	--enable-dfl-baud=57600 \
		--enable-dfl-port=/dev/cuau0 \
		--enable-lock-dir=/var/spool/lock \
		--sysconfdir=${PREFIX}/etc/minicom
LIBS+=		${ICONV_LIB} -lncurses

OPTIONS_DEFINE=		DOCS NLS
OPTIONS_SUB=		yes
NLS_USES=		gettext
NLS_CONFIGURE_ENABLE=	nls

post-patch:
	${REINPLACE_CMD} -e "s@/usr/local/bin/@${LOCALBASE}/bin/@; \
		s@/sz@/lsz@;s@/sb@/lsb@;s@/sx@/lsx@;s@/rz@/lrz@; \
		s@/rb@/lrb@;s@/rx@/lrx@" ${WRKSRC}/src/rwconf.c

post-install:
	${MKDIR} ${STAGEDIR}${ETCDIR}

post-install-DOCS-on:
	@${MKDIR} ${STAGEDIR}${DOCSDIR}
	${INSTALL_DATA} ${WRKSRC}/AUTHORS ${STAGEDIR}${DOCSDIR}/
	${INSTALL_DATA} ${WRKSRC}/ChangeLog ${STAGEDIR}${DOCSDIR}/
	(umask 022 && cd ${WRKSRC} && ${TAR} --exclude '*/Makefile*' \
		 --exclude '*.orig' -chf - extras doc | ${TAR}  -xf - -C \
		${STAGEDIR}${DOCSDIR})

.include <bsd.port.mk>
