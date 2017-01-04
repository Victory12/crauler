#!/usr/bin/perl -w
use strict;
use warnings;
use DDP;
use AnyEvent::HTTP;
use AnyEvent;
use v5.10;
use HTML::LinkExtractor;
my @urls = qw(
	http://tkachov-musey.ru);
my $count = 0;
my $cv = AnyEvent->condvar;
my @size_urls;

my $max = 4;
my $guard;
$guard = http_get $urls[0], sub {
	my ($html) = @_; 
	say "$urls[0] $count received, Size: ", length $html;
	push @size_urls, {url => $urls[0], size => length $html};
	@urls = (@urls, parser($html, @urls)) if $#urls < 1000;
	#p @urls;
	$count+=1;
	for (1 .. $max) {
	   send_url();
	}	
};

$cv->recv;
p @size_urls;
 
sub send_url {
	return if $#size_urls >= 10000;
	my $url = $urls[$count];
	return unless defined $url;
	$count++;
	say "Start ($count) $url";
	$cv->begin;
	http_get $url, sub {
		my ($html) = @_;
		say "$url received, Size: ", length $html;
		push @size_urls, {url => $url, size => length $html};
		@urls = (@urls, parser($html, @urls)) if $#urls < 1000;
		$cv->end;
		send_url();
	};
	return 1;
}

sub parser {
	my $html = shift;
   
    my @urls = @_;
    my $url = $urls[0];
	my $LX = new HTML::LinkExtractor();
    $LX->parse(\$html);
    my $links = $LX->links;
    return undef unless defined $links->[0];
    my @array = @$links;
    my @result;
    for my $link (@array){
    	#p $link;
    	if ( defined $link->{href} and $link->{tag} eq 'a' ){    		
    		if ($link->{href} =~ m[^$url.+]){  
	    		unless ( $link->{href} ~~ @urls )   {
	       	 		push @result, $link->{href};
	       		}    				
    		}
    		if ($link->{href} =~ m[^/[^h].+]){
				#say "HERE $link->{href} $link->{_TEXT}";
    			$link->{href} =~ s[^/(.*)][$url/$1];
    			#say "HERE $1";
    			unless ( $link->{href} ~~ @urls )   {
	       	 		push @result, $link->{href};
	       		}  
    		}
    	}
    }
    my %hash;
    @result = grep{!$hash{$_}++} @result;
   	return @result;

} 
#if