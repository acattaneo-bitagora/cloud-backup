FROM rclone/rclone:latest
COPY docker/rclone/entrypoint.sh /entrypoint.sh
RUN chmod 0755 /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
ENV SCHEDULE="0 0 * * *"

