# Created by: Jean-Yves Lefort <jylefort@brutele.be>

PORTNAME=	viewglob
PORTVERSION=	2.0.4
PORTREVISION=	8
CATEGORIES=	shells
MASTER_SITES=	SF

MAINTAINER=	ports@FreeBSD.org
COMMENT=	GTK+ add-on to bash and zsh

BUILD_DEPENDS=	bash:shells/bash
RUN_DEPENDS=	bash:shells/bash

USES=		gnome pkgconfig xorg
USE_XORG=	x11
USE_GNOME=	gtk20
GNU_CONFIGURE=	yes
LDFLAGS+=	-lm

.include <bsd.port.mk>
