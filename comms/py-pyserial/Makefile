# Created by: Hye-Shik Chang <perky@fallin.lv>

PORTNAME=	pyserial
PORTVERSION=	3.5
PORTREVISION=	1
CATEGORIES=	comms python
MASTER_SITES=	CHEESESHOP
PKGNAMEPREFIX=	${PYTHON_PKGNAMEPREFIX}

MAINTAINER=	sbz@FreeBSD.org
COMMENT=	Serial port encapsulation library for Python

LICENSE=	BSD3CLAUSE
LICENSE_FILE=	${WRKSRC}/LICENSE.txt

USES=		python:3.6+

USE_PYTHON=	distutils autoplist concurrent

NO_ARCH=	yes

do-test:
	${SETENV} PYTHONPATH=${STAGEDIR}${PYTHONPREFIX_SITELIBDIR} ${PYTHON_CMD} ${WRKSRC}/test/test.py

.include <bsd.port.mk>
