FROM rclone/rclone:latest
COPY docker/rclone/entrypoint.sh /entrypoint.sh
RUN chmod 0755 /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
ENV SCHEDULE="0 0 * * *"
ENV GUI_USERNAME=user
ENV GUI_PASSWORD=password
ENV PORT=8089
EXPOSE 8089