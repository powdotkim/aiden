%define SERVICE_HTPP_version "1"
%define SERVICE_HTTP_revision "0"

%MACRO service_http_macro_foot 0
    db "<hr/>", STATIC_ASCII_NEW_LINE
    db "aiden v", KERNEL_version, ".", KERNEL_revision, " (HTTP Service v", SERVICE_HTTP_version, ".", SERVICE_HTTP_revision, ")"
%ENDMACRO

service_http:
    mov cx, 80
    call kernel_network_tcp_port_assign

.loop:
    call kernel_network_tcp_port_receive
    jc .loop

    xchg bx, bx

    mov ecx, service_http_get_root_end - service_http_get_root
    mov rdi, service_http_get_root
    call library_string_compare
    jc .no

    mov ecx, service_http_200_default_end - service_http_200_default
    mov rsi, service_http_200_default

    jmp .answer

.no:
    mov ecx, service_http_404_end - service_http_404
    mov rsi, service_http_404

.answer:
    call kernel_network_tcp_port_send
    jmp $

service_http_get_root db "GET / "
service_http_get_root_end:

service_http_200_default    db "HTTP/1.0 200 OK", STATIC_ASCII_NEW_LINE
                            db "content-type: text/html", STATIC_ASCII_NEW_LINE
                            db STATIC_ASCII_NEW_LINE
                            db "<style> * {font: 12px/150%} 'Courier New', Monospace, Verdana; }</style>", STATIC_ASCII_NEW_LINE
                            db "seketika admin murka >:(", STATIC_ASCII_NEW_LINE
                            service_http_macro_foot
service_http_200_default_end:

service_http_404		db	"HTTP/1.0 404 Not Found", STATIC_ASCII_NEW_LINE
				        db	"Content-Type: text/html", STATIC_ASCII_NEW_LINE
				        db	STATIC_ASCII_NEW_LINE
				        db	"404 Content not found.", STATIC_ASCII_NEW_LINE
                        service_http_macro_foot
service_http_404_end: