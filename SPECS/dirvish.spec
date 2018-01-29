Name:           dirvish-btrfs
Version:        1.2.1
Release:        1%{?dist}
Summary:        Dirvish
License:        GPL
URL:            http://www.dirvish.org

Source0:        http://www.dirvish.org/dirvish-%{version}.tgz
Source1:        https://raw.githubusercontent.com/keachi/dirvish-rpm/master/SOURCES/master.conf#/%{name}-%{version}.conf
Patch0:         https://raw.githubusercontent.com/keachi/dirvish-rpm/master/SOURCES/01-imsort-reserved-warning.patch
BuildArch:      noarch

Requires:       rsync

BuildRequires:  perl

%description
Dirvish is a fast, disk based, rotating network backup system.

%prep
%setup -q -n dirvish-%{version}
%patch -P 0 -p 1

%build
EXECUTABLES="dirvish dirvish-runall dirvish-expire dirvish-locate"
MAN8PAGES="dirvish.8 dirvish-runall.8 dirvish-expire.8 dirvish-locate.8"
MAN5PAGES="dirvish.conf.5"

HEADER="#!/usr/bin/env perl

\$CONFDIR = \"/etc/dirvish\";

"

# create executables
for f in $EXECUTABLES; do
  echo "$HEADER" > "$f"
  cat "${f}.pl" >> "$f"
  cat "loadconfig.pl" >> "$f"
done

# compress manpages
for f in $MAN8PAGES $MAN5PAGES; do
  gzip -cf "${f}" > "${f}.gz"
done

%install
EXECUTABLES="dirvish dirvish-runall dirvish-expire dirvish-locate"
MAN8PAGES="dirvish.8 dirvish-runall.8 dirvish-expire.8 dirvish-locate.8"
MAN5PAGES="dirvish.conf.5"

mkdir -p %{buildroot}/usr/{bin,share/man/man{5,8}}

# install executables
for f in $EXECUTABLES; do
  install -Dm755 "$f" "%{buildroot}%{_prefix}/bin/${f}"
done

# install manpages
for f in $MAN8PAGES; do
  install -Dm644 "${f}.gz" "%{buildroot}%{_mandir}/man8/${f}.gz"
done
for f in $MAN5PAGES; do
  install -Dm644 "${f}.gz" "%{buildroot}%{_mandir}/man5/${f}.gz"
done

mkdir -p %{buildroot}/etc/dirvish/

# create directory for configs
install -Dm644 %{SOURCE1} "%{buildroot}%{_sysconfdir}/dirvish/master.conf"

%{_fixperms} $RPM_BUILD_ROOT/*

%files
%doc CHANGELOG RELEASE.html COPYING TODO.html FAQ.html INSTALL
%config(noreplace)%{_sysconfdir}/dirvish/master.conf
%{_mandir}/man5/*
%{_mandir}/man8/*
%{_prefix}/bin/dirvish
%{_prefix}/bin/dirvish-expire
%{_prefix}/bin/dirvish-locate
%{_prefix}/bin/dirvish-runall
