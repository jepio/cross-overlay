# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit autotools multilib-minimal toolchain-funcs

DESCRIPTION="Transport Independent RPC library (SunRPC replacement)"
HOMEPAGE="http://libtirpc.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2
	mirror://gentoo/${PN}-glibc-nfs.tar.xz"

LICENSE="GPL-2"
SLOT="0/3" # subslot matches SONAME major
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-linux ~arm-linux ~x86-linux"
IUSE="ipv6 kerberos static-libs"

RDEPEND="kerberos? ( >=virtual/krb5-0-r1[${MULTILIB_USEDEP}] )"
DEPEND="${RDEPEND}
	app-arch/xz-utils
	>=virtual/pkgconfig-0-r1[${MULTILIB_USEDEP}]"

PATCHES=(
	"${FILESDIR}/${PN}-1.0.2-bcopy-to-memmove.patch"
)

src_prepare() {
	cp -r "${WORKDIR}"/tirpc "${S}"/ || die
	default
	eapply_user
	eautoreconf
}

multilib_src_configure() {
	local myeconfargs=(
		$(use_enable ipv6)
		$(use_enable kerberos gssapi)
		$(use_enable static-libs static)
		"ac_cv_prog_KRB5_CONFIG=${EROOT}/usr/bin/krb5-config"
	)
	ECONF_SOURCE="${S}" econf "${myeconfargs[@]}"
}

multilib_src_install() {
	default

	# libtirpc replaces rpc support in glibc, so we need it in /
	gen_usr_ldscript -a tirpc
}

multilib_src_install_all() {
	einstalldocs

	insinto /etc
	doins doc/netconfig

	insinto /usr/include/tirpc
	doins -r "${WORKDIR}"/tirpc/*

	# makes sure that the linking order for nfs-utils is proper, as
	# libtool would inject a libgssglue dependency in the list.
	if ! use static-libs ; then
		find "${ED}" -name "*.la" -delete || die
	fi
}
