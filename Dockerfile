FROM nginx
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 80
CMD /bin/bash -c "nginx -g 'daemon off;' & sleep 86400 && kill -9 0"