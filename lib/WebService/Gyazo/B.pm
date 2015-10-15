package WebService::Gyazo::B;

use strict;
use warnings;

use WebService::Gyazo::B::Image;

use LWP::UserAgent;
use LWP::Protocol::socks;
use HTTP::Request::Common;
use URI::Simple;

our $VERSION = '0.0403';

use constant {
	HTTP_PROXY => 'http',
	SOCKS4_PROXY => 'socks4',
	SOCKS5_PROXY => 'socks',
	HTTPS_PROXY => 'https',
};

sub new {
	my ($self, %args) = @_;
	$self = bless(\%args, $self);

	return $self;
}

# Get/set error message
sub error {
	my ( $self, $error_str ) = @_;
	if ( $error_str ) {
		$self->{error} = $error_str;
		return 0;
	}
	return $self->{error} || 'N/A';
}

sub isError {
	return shift->{error} ? 1 : 0;
}

# Set proxy
sub setProxy {
	my ($self, $proxyStr) = @_;

	return $self->error('Undefined proxy value!') unless $proxyStr;

	# If $proxyStr was passed, get protocol, ip and port from it
	my $proxyUrl = URI::Simple->new($proxyStr);

	# Check if we have protocol and host/ip from proxy string
	unless ( $proxyUrl->protocol && $proxyUrl->host ) {
		retrun $self->error('Wrong proxy protocol or hostname!')
	}

	# Check if protocol is correct
	unless ( grep { $proxyUrl->protocol eq $_ } ( HTTP_PROXY, HTTPS_PROXY, SOCKS4_PROXY, SOCKS5_PROXY ) ) {
		return $self->error('Wrong protocol type: ' . $proxyUrl->protocol)
	}

	# Check if port is correct
	if ( $proxyUrl->port && $proxyUrl->port > 65535 ) {
		return $self->error('Wrong proxy port!')
	}

	$self->{proxy} = sprintf("%s://%s:%s", $proxyUrl->protocol, $proxyUrl->host, $proxyUrl->port || 80);

	return 1;
}

# Assign ID
sub setId {
	my ($self, $id) = @_;

	# Check the length of ID
	return $self->error('Wrong id syntax!')
		unless defined $id && $id =~ m#^\w{1,14}$#;

	$self->{id} = $id;

	return 1;
}

# Upload file
sub uploadFile {
	my ($self, $filename) = @_;

	# Assign ID unless already assigned
	unless ($self->{id}) {
		$self->{id} = time();
	}

	# Check if file path was passed
	unless (defined $filename) {
		return $self->error('File parameter was not specified or is undef!');
	}

	# Check if it is a file
	unless (-f $filename) {
		return $self->error('File parameter to uploadFile() was not found!');
	}

	# Check if file is readable
	unless (-r $filename) {
		return $self->error('The file parameter to uploadFile() is not readable!');
	}

	# Create user agent object
	$self->{ua} = LWP::UserAgent->new('agent' => 'Gyazo/'.$VERSION) unless (defined $self->{ua});

	# Assign proxy if it was passed
	$self->{ua}->proxy(['http'], $self->{proxy}.'/') if ($self->{proxy});

	# Create object for POST-request
	my $req = POST('https://gyazo.com/upload.cgi',
		'Content_Type' => 'form-data',
		'Content' => [
			'id' => $self->{id},
			'imagedata' => [$filename],
		]
	);

	# Send POST-request and check the response
	my $res = $self->{ua}->request($req);
	if (my ($id) = ($res->content) =~ m#https://gyazo.com/(\w+)#is) {
		return WebService::Gyazo::B::Image->new(id => $id);
	} else {
		retur $self->error("Cannot parsed URL in the:\n".$res->as_string."\n");
	}
}

1;

__END__

=head1 NAME

WebService::Gyazo::B - a Perl image upload library for gyazo.com

=head1 SYNOPSIS

	use WebService::Gyazo::B;

	my $newUserId = time();

	my $upAgent = WebService::Gyazo::B->new(id => $newUserId);
	print "Set user id [".$newUserId."]\n";

	my $image = $upAgent->uploadFile('1.jpg');

	unless ($upAgent->isError) {
		print "Image uploaded [".$image->getImageUrl()."]\n";
	} else {
		print "Error:\n".$upAgent->error()."\n\n";
	}

=head1 DESCRIPTION

B<WebService::Gyazo::B> helps you to upload images to gyazo.com (via regular expressions and LWP).

It is a fork of L<WebService::Gyazo> by Shlomi Fish, which was done to make
the deployment of some code he has written for a commission easier.

=head1 METHODS

=head2 C<new>

	my $userID = time();
	my $wsd = WebService::Gyazo::B->new(id => $userID);

Constructs a new C<WebService::Gyazo::B> object.
Parameter id is optional, if the parameter is not passed, it will take the value of the time() function.

=head2 C<setProxy>

	my $proxy = 'http://1.2.3.4:8080';
	if ($wsd->setProxy($proxy)) {
		print "The proxy [$proxy] was set!";
	} else {
		print "The proxy was not set! Error [".$wsd->error."]";
	}

Set the proxy C<1.2.3.4:8080> and the protocol http for the C<LWP::UserAgent>
object.

=head2 C<error>

	print "Error [".$wsd->error."]" if ($wsd->isError);

This method return text of last error.

=head2 C<isError>

	print "Error [".$wsd->error."]" if ($wsd->isError);

This method return 1 if $wsd->{error} not undef, else return 0.

=head2 C<setId>

	my $newUserId = time();
	if ($wsd->setId($newUserId)) {
		print "User id [".$newUserId."] seted!";
	} else {
		print "User id not seted! Error [".$wsd->error."]";
	}

This method set new gyazo user id.

=head2 C<uploadFile>

	my $result = $upAgent->uploadFile('1.jpg');

	if (defined($result) and !$upAgent->isError) {
		print "Returned result[".$result->getImageUrl()."]\n";
	} else {
		print "Error:\n".$upAgent->error()."\n\n";
	}

This metod return object WebService::Gyazo::B::Image.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Gyazo::B

=head1 SEE ALSO

L<WebService::Gyazo::B::Image>, L<LWP::UserAgent>.

=head1 AUTHOR

Modified by Shlomi Fish, 2015 (L<http://www.shlomifish.org/>) while
disclaiming all rights.

SHok, <shok at cpan.org> (L<http://nig.org.ua/>)

=head1 COPYRIGHT

Copyright 2013-2014 by SHok

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
