#define _GNU_SOURCE

#include <errno.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

// FIXME: Error handling

int
UnixDomainSocket_Create (void)
{
  return socket (AF_UNIX, SOCK_STREAM/* | SOCK_NONBLOCK*/, 0); // FIXME: Handle type being chosen by user
}

void
UnixDomainSocket_Connect (int fd, const char *path)
{
  struct sockaddr_un addr;
  memset (&addr, 0, sizeof (struct sockaddr_un));
  addr.sun_family = AF_UNIX;
  strncpy (addr.sun_path, path, sizeof(addr.sun_path) - 1);
  connect (fd, (const struct sockaddr *) &addr, sizeof (addr));
}

int
UnixDomainSocket_SendCredentials (int fd)
{
  struct msghdr header = { 0 };
  struct iovec iov[1];
  char iov_data[1] = { 0 };
  char buffer[CMSG_SPACE (sizeof (struct ucred))] = { 0 };
  struct cmsghdr *cmsg;
  struct ucred *credentials;

  header.msg_iov = iov;
  header.msg_iovlen = 1;
  header.msg_control = buffer;
  header.msg_controllen = sizeof (buffer);
  iov[0].iov_base = iov_data;
  iov[0].iov_len = 1;
  cmsg = CMSG_FIRSTHDR (&header);
  cmsg->cmsg_level = SOL_SOCKET;
  cmsg->cmsg_type = SCM_CREDENTIALS;
  cmsg->cmsg_len = CMSG_LEN (sizeof (struct ucred));
  credentials = (struct ucred *) CMSG_DATA (cmsg);
  credentials->pid = getpid ();
  credentials->uid = getuid ();
  credentials->gid = getgid ();
  sendmsg (fd, &header, 0);

  return credentials->uid;
}

int
UnixDomainSocket_GetError ()
{
  return errno;
}
