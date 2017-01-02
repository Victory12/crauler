#!/usr/bin/perl -w
use strict;
use warnings;
use DDP;
use AnyEvent::HTTP;
use AnyEvent;
use v5.10;
 
my @urls = qw(

	https://perlmaven.com/pm/login
);
my @size_urls;
my $count = 0;
my $cv = AnyEvent->condvar;

my $url = $urls[$count];
$count++;
my $gua;
$gua = http_get 
	$url, 
	sub {
		my ( $body, $head) = @_;
		push @size_urls, {url => $url, size => length $body};
		undef $gua;
		@urls = (@urls, get_data($body, $url, @urls));
		while ($#size_urls < 200) {
   			send_url();
		}
	};

$cv->recv;
@size_urls = reverse sort { $a->{size} <=> $b->{size} } @size_urls;
p @size_urls;


sub send_url {
	$url = $urls[$count];
	return if not $url;
	$count++;
	say "Start ($count) $url";
	p @urls;
	$cv->begin;
	my $guard;
	$guard = http_get $url, sub {
		my ( $body, $head) = @_;
		say "$url work";
		push @size_urls, {url => $url, size =>  length $body};
		@urls = (@urls, get_data($body, $url, @urls));
		p @urls;
		p @size_urls;
		$cv->end;
		send_url();
	};
	return 1;
}

sub get_data{
    my $body = shift;
    my $url = shift;
    my @urls = @_;
    my @array;
    $body =~ s[<head>(.*)</head>][]s;
    while($body =~ s[href="($url[^"]*|/[^"]*)"][]s){
       my $str = $1;
       $str =~ s[^/(.*)][https://perlmaven.com/$1];      
       unless ( $str ~~ @urls )   {
       	  push @array,$str;
       }  
    }
    my %hash;
    @array=grep{!$hash{$_}++} @array;
    return @array;
}